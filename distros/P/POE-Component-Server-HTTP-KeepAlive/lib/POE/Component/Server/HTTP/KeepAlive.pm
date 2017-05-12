package POE::Component::Server::HTTP::KeepAlive;
use strict;
use HTTP::Status;
use Carp;

use Exporter ();
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);

use POE;

$VERSION = "0.0307";

my $N++;

use constant DEBUG => 0;

use Carp;

################################################
sub new 
{
    my $class = shift;
    my $self = bless {@_}, $class;

    unless( defined $self->{total_max} ) {
        $self->{total_max} = 10;
    }

    unless( defined $self->{timeout} ) {
        $self->{timeout} = 60;
    }
    unless( defined $self->{max} ) {
        $self->{max} = 10;
    }
    if( $self->{max} > $self->{total_max} ) {
        $self->{max} = $self->{total_max};
    }

    unless( $self->{http_alias} ) {
        $self->{http_alias} = $self->{http_ID} =
                $POE::Kernel::poe_kernel->get_active_session->ID;
    }

    $self->{connections} = {};
    die "Must have a session alias" unless $self->{http_alias};
    $self->create_events;
    return $self;
}

################################################
sub create_events
{
    my( $self ) = @_;

    my $id = $self;
    $self->{timeout_event} = "$self TIMEOUT";
    $POE::Kernel::poe_kernel->state( $self->{timeout_event}, $self, 'timeout_event' );
    $self->{close_event} = "$self CLOSE";
    $POE::Kernel::poe_kernel->state( $self->{close_event}, $self, 'close_event' );
}

################################################
## A request has started.
sub start
{
    my( $self, $req, $resp ) = @_;
    my $c = $self->conn_from_resp( $resp );
    return unless $c;

    # remove timeout for the connection
    my $ka = $self->get( $self->conn_ID( $c ) );
    return unless $ka;          # this is normal; first req of connection

    # Make sure the connection doesn't timeout while a request is active
    if( $ka->{alarm} ) {
        $POE::Kernel::poe_kernel->alarm_remove( delete $ka->{alarm} );
    }
}

################################################
## A request has ended
## Make a descision about keep-alive
sub finish
{
    my( $self, $req, $resp ) = @_;
    my $c = $self->conn_from_resp( $resp );

    my $id = $self->conn_ID( $c );

# Lifted from apache :
#     *   IF  we have not marked this connection as errored;
    if( !$resp->is_error and
#     *   and the response body has a defined length due to the status code
#     *       being 304 or 204, the request method being HEAD, already
#     *       having defined Content-Length or Transfer-Encoding: chunked, or
#     *       the request version being HTTP/1.1 and thus capable of being set
#     *       as chunked [we know the (r->chunked = 1) side-effect is ugly];
#        ( defined $resp->content_length ) and
#     *   and the server configuration enables keep-alive;
        ( $self->{total_max} > 0 ) and
#     *   and the server configuration has a reasonable inter-request timeout;
        ( $self->{timeout} > 0 ) and
#     *   and there is no maximum no requests or the max hasn't been reached;
        ( $self->{max} <= 0 or $self->{max} > $self->conn_ka( $c ) ) and
#     *   and the response status does not require a close;
        ( not $self->status_close( $resp ) ) and
#     *   and the response generator has not already indicated close;
        ( not $self->connection( $resp, 'close' ) ) and
#     *   and the client did not request non-persistence (Connection: close);
        ( not $self->connection( $req, 'close' ) ) and
#     *   and    we haven't been configured to ignore the buggy twit
#     *       or they're a buggy twit coming through a HTTP/1.1 proxy
        ( 1 ) and # ???
#     *   and    the client is requesting an HTTP/1.0-style keep-alive
#     *       or the client claims to be HTTP/1.1 compliant (perhaps a proxy);
        ( $self->connection( $req, 'keep-alive' ) or $req->protocol eq 'HTTP/1.1' )
#     *   THEN we can be persistent, which requires more headers be output.
#     *
      ) {
        # warn "max=$self->{max} conn_ka=", $self->conn_ka( $c );
        DEBUG and 
            warn "Keepalive: finish keep id=$id";
        $self->keep( $req, $c );
        $self->keep_response( $req, $resp, $c );
        return 1;
    }
    else {
        DEBUG and 
            warn "Keepalive: finish drop id=$id";
        $self->drop( $id );
        $self->drop_response( $req, $resp, $c );
        return;
    }

}

################################################
sub status_close
{
    my( $self, $resp ) = @_;
    my $status = $resp->code;

    return (($status == RC_BAD_REQUEST) or
            ($status == RC_REQUEST_TIMEOUT) or
            ($status == RC_LENGTH_REQUIRED) or
            ($status == RC_REQUEST_ENTITY_TOO_LARGE) or
            ($status == RC_REQUEST_URI_TOO_LARGE) or
            ($status == RC_INTERNAL_SERVER_ERROR) or
            ($status == RC_SERVICE_UNAVAILABLE) or
            ($status == RC_NOT_IMPLEMENTED)
           );
}


################################################
# It turns out the Connection header can contain multiple
# comma separated values
sub connection
{
    my( $self, $r, $keyword ) = @_;
    my $conn = $r->header( 'Connection' );
    return 0 unless $conn;
    $conn = lc $conn;
    return( ( 0 <= index ",$conn,", lc ",$keyword," ) ? 1 : 0 );
}

################################################
sub timeout
{
    my( $self, $req ) = @_;

    my $timeout = $self->{timeout};

    # find out how long the client wants us to keep it open
    my $ka_header = $req->header( 'keep-alive' );
    if( $ka_header and ( $ka_header =~ /^(\d+)$/ or 
                         $ka_header =~ /timeout=(\d+)/ ) ) {
        if( $1 > 0 && $1 < $timeout ) {
            $timeout = $1;
        }
    }
    return $timeout;
}

################################################
## Add headers to HTTP response that marks this conneciton
## as keep-alive
sub keep_response
{
    my( $self, $req, $resp, $c ) = @_;
    
    my $timeout = $self->timeout( $req );

    if( $self->connection( $req, 'keep-alive' ) ) {
        my $left = $self->{max} - $self->conn_ka( $c );
        $left = $self->{total_max} if $self->{total_max} < $left;
        $resp->header( 'Keep-Alive' => "timeout=$timeout, max=$left" );
        my $conn = $resp->header( 'Connection' );
        if( $conn ) {
            unless( $self->connection( $resp, 'Keep-Alive' ) ) {
                $conn .= ",Keep-Alive";
            }
        }
        else {
            $conn = "Keep-Alive";
        }
        $resp->header( Connection => $conn );
        # XXX: a Connection header might be a problem for HTTP/0.9 
    }
}

################################################
## Add headers to HTTP response that marks this conneciton
## as NOT keep-alive
sub drop_response
{
    my( $self, $req, $resp ) = @_;
    

    $resp->remove_header( 'Keep-Alive' );
    unless( $self->connection( $resp, 'close' ) ) {
        my $conn = $resp->header( 'Connection' );
        if( $conn and $conn =~ s/\bKeep-Alive\b/close/i ) {
            # yep yep
        }
        elsif( $conn ) {
            $conn .= ",close";
        }
        else {
            $conn = "close";
        }
        $resp->header( Connection => $conn );
        # XXX: a Connection header might be a problem for HTTP/0.9 
    }
}


################################################
sub keep
{
    my( $self, $req, $c ) = @_;
    my $id = $self->conn_ID( $c );
    DEBUG and 
        warn "Keepalive: Connection id=$id keep";

    # Note that $id shouldn't be in {connection}... start() called
    # ->drop() on it.
    my $ka = { id=>$id, N=>$N++ };
    $self->add( $ka );
    $self->conn_ka_inc( $c );
    $self->conn_on_close( $c, $id );
    $self->enforce;

    DEBUG and
        $self->dump;

    # setup a timeout
    my $timeout = $self->timeout( $req );
    if( $timeout ) {
        $ka->{alarm} = $POE::Kernel::poe_kernel->delay_set( 
                                               $self->{timeout_event},
                                               $timeout, 
                                               $id
                                             );
        DEBUG and 
            warn "Keepalive: timeout for id=$id is alarm=$ka->{alarm}";
    }
}

################################################
## Add an keep-alive struct to the connection list
sub add
{
    my( $self, $ka ) = @_;
    $self->{connections}{ $ka->{id} } = $ka;
}

################################################
## Make sure the connection list doesn't grow to big
sub enforce
{
    my( $self ) = @_;
    return unless $self->{total_max} > 0;

    my $n = keys( %{ $self->{connections} } ) - $self->{total_max};
    return unless $n > 0;

    # find $n connections to drop
    my @remove;
    foreach my $ka ( sort { $a->{N} <=> $b->{N} } 
                    values %{ $self->{connections} } ) {
        push @remove, $ka;
        last if $n == 0+@remove;
    }
    return unless @remove;

    foreach my $ka ( @remove ) {
        # Because ->enforce could be called multiple times before
        # the connection is actually closed, we mark $ka as dropped
        # and don't call ->conn_close more then once
        next if $ka->{drop};
        $ka->{drop} = 1;
        my $drop = $self->conn_get( $ka->{id} );
        $self->conn_close( $drop, $ka->{id} );
    }
}

################################################
## Remove a struct from the connection list
sub remove
{
    my( $self, $id ) = @_;
    return delete $self->{connections}{ $id };
}

################################################
## Find a struct from the connection list
sub get
{
    my( $self, $id ) = @_;
    return $self->{connections}{ $id };
}


################################################
## We want to remove all internal state regarding a connection
## Note, we must not die nor even warn on bad happenings
sub drop
{
    my( $self, $id ) = @_;

    DEBUG and 0 and do {
                warn "Keepalive: Going to drop id=$id";
                $self->dump();
            };

    my $ka = $self->remove( $id );
    unless( $ka ) {
        DEBUG and do {
                warn "Keepalive: Can't find id=$id";
                $self->dump();
            };
        # Note: not finding $id is normal for the first request of a connection
        return;
    }

    DEBUG and 
        warn "Keepalive: drop id=$id alarm=", ($ka->{alarm}||'');
    DEBUG and
            $self->dump;

    if( $ka->{alarm} ) {
        $POE::Kernel::poe_kernel->alarm_remove( delete $ka->{alarm} );
    }

    return;
}

################################################
sub close_event
{
    my( $self, $id ) = @_[OBJECT, ARG0];
    DEBUG and  
        warn "Keepalive: close_event id=$id";
    $self->drop( $id );
}

################################################
sub timeout_event
{
    my( $self, $id ) = @_[OBJECT, ARG0];
    DEBUG and  
        warn "Keepalive: timeout_event id=$id";
    my $c = eval { $self->conn_get( $id ) };

    unless( $c ) {
        warn "Keepalive: timeout_event unknown connection id=$id";
        return;
    }

    my $ka = $self->get( $id );
    unless( $ka ) {
        DEBUG and warn "Keepalive: timeout_event connection id=$id wasn't kept-alive";
        return;
    }
    delete $ka->{alarm};

    # conn_close should provoke a close_event, which then calls ->drop
    return if $self->conn_close( $c, $id );
    # conn_close returning false means the connection was active
    # Which is highly strange...
}

################################################
sub dump
{
    my( $self ) = @_;
    warn "Keepalive: total_max=$self->{total_max} [", 
                ( join ', ', map { "id=$_->{id}" } 
                        sort { $a->{N} <=> $b->{N} } 
                        values %{ $self->{connections} } ), 
            "]";
}


############################################################################
## Here is where we strap on the big boots and stomp all over the object
## encapsulation.  Because, damnit, the HTTP modules don't provide the access
## we need to get our job done
## Look for STOMP for particularly egregarious bits

################################################
## Get the heap of the HTTP session
sub get_heap
{
    my( $self ) = @_;

    # http_alias could be an alias, or a session ID..
    my $session;
    if( $self->{http_ID} ) {
        $session = 
            $POE::Kernel::poe_kernel->ID_id_to_session( $self->{http_ID} );
    }
    else {
        $session = 
            $POE::Kernel::poe_kernel->alias_resolve( $self->{http_alias} );
    }
    croak "Session $self->{http_alias} no longer exists" unless $session;
    return $session->get_heap;
}

################################################
sub conn_ID
{
    my( $self, $c ) = @_;
    return $c->ID;
}

################################################
sub conn_from_resp
{
    my( $self, $resp ) = @_;
    return $resp->connection;
}

################################################
## Get the connection, based on its ID
sub conn_get
{
    my( $self, $id ) = @_;
    my $heap = $self->get_heap;
    if( $heap->{c}->{$id} ) {               # STOMP
        return $heap->{c}->{ $id };
    }
    die "$heap doesn't have id=$id";
    return;
}

################################################
## Get the connection's wheel, based on its ID
sub conn_wheel
{
    my( $self, $id ) = @_;
    my $heap = $self->get_heap;
    if( $heap->{wheels}->{$id} ) {               # STOMP
        return $heap->{wheels}->{ $id };
    }
    die "$heap doesn't have id=$id";
    return;
}

################################################
## Close the connection.  Must provoke an on_close()
sub conn_close
{
    my( $self, $c, $id ) = @_;
    $id ||= $self->conn_ID( $c );

    # tell the httpd poco that the connection is closed
    # We avoid a race condition by making sure the connection isn't active
    unless( $c->{request} ) {
        my $wheel = $self->conn_wheel( $id );
        # Hope this provokes an error event!
        eval { local $^W = 0; 
               shutdown( $wheel->[0], 0 );    # STOMP
             };
        return 1;
    }
    DEBUG and warn "Keepalive: close, but request is active";
    return 0;
}


################################################
## Register an event that is called when the connection is closed by
## the component
sub conn_on_close
{
    my( $self, $c, $id ) = @_;
    $id ||= $self->conn_ID( $c );
    $c->on_close( $self->{close_event}, $id );
}


################################################
## Increment a connection's request count
sub conn_ka_inc
{
    my( $self, $c ) = @_;
    $c->{keepalives}++;             # STOMP
}

################################################
## Return the connections's request count
sub conn_ka
{
    my( $self, $c ) = @_;
    return $c->{keepalives}||0;     # STOMP
}


1;
__END__


=head1 NAME

POE::Component::Server::HTTP::KeepAlive - HTTP keep-alive support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Handlers

=head1 EVENTS

=head1 See Also

Please also take a look at L<POE::Component::Server::HTTP> and
L<POE::Component::Server::SimpleHTTP>.

=head1 TODO

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
=head1 AUTHOR

Additional hacking by Philip Gwyn, poe-at-pied.nu

=cut
