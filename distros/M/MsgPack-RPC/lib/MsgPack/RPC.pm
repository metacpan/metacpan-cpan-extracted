package MsgPack::RPC;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: MessagePack RPC client
$MsgPack::RPC::VERSION = '1.0.1';

use strict;
use warnings;

use Moose;

use IO::Socket::INET;
use IO::Socket::UNIX;
use MsgPack::Decoder;
use MsgPack::Encoder;
use MsgPack::RPC::Message;
use MsgPack::RPC::Message::Request;

use Promises qw/ deferred /;

use experimental 'signatures';

with 'Beam::Emitter';
with 'MooseX::Role::Loggable' => {
    -excludes => [ 'Bool' ],
};

has io => (
    required => 1,
    is       => 'ro',
    trigger  => \&_set_io_accessors,
);


sub _set_io_accessors($self,$io,@) {
    if( ref $io eq 'ARRAY' ) {
        $self->_io_read(sub{ 
            my $buffer;
            1 until read $io->[0], $buffer, 1;
            $buffer;
        });

        $self->_io_write(sub(@stuff){
            print { $io->[1] } @stuff
                or die "couldn't write to output\n";
        });
    }
    elsif( not ref $io ) {
        if( $io =~ /:/ ) {
            $self->socket( IO::Socket::INET->new( 
                    Proto => 'tcp',
                    Timeout => 60, PeerAddr => $io, Blocking => 1) or die "couldn't connect to socket '$io': $!\n" );
        }
        else {
            $self->socket( IO::Socket::UNIX->new(
                    Peer => $io,
            ));
        }

        $self->_io_read(sub{
            my $buffer;
            $self->socket->recv($buffer, 1);
            $buffer;
        });
        $self->_io_write(sub{
            $self->socket->send(@_);
        });
    }
    else {
        die "don't know how to deal with '$io'";
    }
}

has [ qw/ _io_read _io_write / ] => ( is => 'rw' );

has "socket" => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $addie = join ':', $self->host, $self->port;

        IO::Socket::INET->new( $addie )
            or die "couldn't connect to $addie";
    },
);

has decoder => (
    isa => 'MsgPack::Decoder',
    is => 'ro',
    lazy => 1,
    default => sub {
        MsgPack::Decoder->new(
            logger => $_[0]->logger
        );
    },
);

has "response_callbacks" => (
    is => 'ro',
    lazy => 1,
    default => sub {
        {};
    },
);

sub add_response_callback {
    my( $self, $id ) = @_;
    my $deferred = deferred;
    $self->response_callbacks->{$id} = {
        timestamp => time,
        deferred => $deferred,
    };

    $deferred;
}

sub request($self,$method,$args=[],$id=++$MsgPack::RPC::MSG_ID) {
    $self->send([ 0, $id, $method, $args ]);
    $self->add_response_callback($id);
}

sub response($self,$id,$args) {
    $self->send([ 1, $id, undef, $args]);
}

sub response_error($self,$id,$args) {
    $self->send([ 1, $id, $args, undef]);
}

sub notify($self,$method,$args=[]) {
    $self->send([2,$method,$args]);
}

sub send($self,$struct) {
    $self->log( [ "sending %s", $struct] );

    my $encoded = MsgPack::Encoder->new(struct => $struct)->encoded;

    $self->log_debug( [ "encoded: %s", $encoded ] );
    $self->_io_write->($encoded);
}

sub emit_request($self,$id,$method,$args) {
    $self->log_debug( [ "received a '%s(%s)' request", $method,$args ] );
    $self->emit( $method, class => 'MsgPack::RPC::Message::Request', 
        args => $args, message_id => $id );     
}

sub emit_notification($self,$method,$args) {
    $self->log_debug( [ "it's a '%s' notification", $method ] );
    $self->emit( $method, class => 'MsgPack::RPC::Message', args => $args );     
}

sub loop {
    my $self = shift;
    my $until = shift;

    while ( ) {
        my $byte = $self->_io_read->();
        #    warn ord($byte)."!\n";
        $self->decoder->read( $byte );

        while( $self->decoder->has_buffer ) {
            my $next = $self->decoder->next;
            $self->log( [ "receiving %s" , $next ]);

            if ( $next->[0] == 1 ) {
                $self->log_debug( [ "it's a response for %d", $next->[1] ] );
                if( my $callback =  $self->response_callbacks->{$next->[1]} ) {
                    my $f = $callback->{deferred};
                    $next->[2] 
                        ? $f->reject($next->[2])
                        : $f->resolve($next->[3])
                        ;
                }
            }
            elsif( $next->[0] == 2 ) {
                $self->emit_notification($next->[1],$next->[2]);
            }
            elsif( $next->[0] == 0 ) {
                $self->emit_request($next->[1], $next->[2], $next->[3]);
            }

            if( defined $until ) {
                if( ref $until eq 'CODE' ) {
                    return if $until->();
                }
                elsif( eval { $until->isa('Future') } ) {
                    return if $until->is_done;
                }
                elsif( eval { $until->can('is_in_progress') } ) {
                    return unless $until->is_in_progress;
                }
                else {
                    return if $until and not --$until;
                }
            }

        }
    }
}
    

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC - MessagePack RPC client

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use MsgPack::RPC;

    my $rpc = MsgPack::RPC->new( io => '127.0.0.1:6666' );

    $rpc->notify( 'something' => [ 'with', 'args' ] );

    $rpc->request( 
        request_method => [ 'some', 'args' ] 
    )->on_done(sub{
        my $resp = @_;

        print "replied with: ", @_;
    });

    $rpc->loop;

=head1 DESCRIPTION

C<MsgPack::RPC> implements a MessagePack RPC client following
the protocol described at L<https://github.com/msgpack-rpc/msgpack-rpc/blob/master/spec.md>.

=head1 METHODS

C<MsgPack::RPC> consumes the role L<MooseX::Role::Loggable>, and thus has all its
exported methods.

=head2 new( %args )

The class constructor takes all the arguments for L<MooseX::Role::Loggable>, plus the following:

=over

=item io( [ $in_fh, $out_fh ] )

=item io( $socket )

Required. Defines which IO on which the MessagePack messages will be received and sent.

The IO can be a local socket (e.g., C</tmp/rpc.socket> ), a network socket (e.g., C<127.0.0.1:6543>),
or a pair of filehandles.

=back

=head2 io()

Returns the IO descriptor(s) used by the object.

=head2 request( $method, $args, $id )

Sends the request. The C<$id> is optional, and will be automatically
assigned from an internal self-incrementing list if not given.

Returns a promise that will be fulfilled once a response is received. The response can be either a success 
or a failure, and in both case the fulfilled promise will be given whatever values are passed in the response.

    $rpc->request( 'ls', [ '/home', '/tmp' ] )
        ->on_done(sub{ say for @_ })
        ->on_fail(sub{ die "couldn't read directories: ", @_ });

=head2 notify( $method, $args )

Sends a notification. 

=head2 subscribe( $event_name, \&callback ) 

    # 'ping' is a request
    $rpc->subscribe( ping => sub($msg) {
        $msg->response->done('pong');
    });

    # 'log' is a notification
    $rpc->subscribe( log => sub($msg) {
        print {$fh} @{$msg->args};
    });

Register a callback for the given event. If a notification or a request matching the
is received, the callback will be called. The callback will be passed either a L<MsgPack::RPC::Message> (if triggered by
a notification) or
L<MsgPack::RPC::Message::Request> object.

Events can have any number of callbacks assigned to them. 

The subscription system is implemented using the L<Beam::Emitter> role.

=head2 loop( $end_condition )

Reads and process messages from the incoming stream, endlessly if not be given an optional C<$end_condition>.
The end condition can be given a number of messages to read, or a promise that will end the loop once 
fulfilled.

    # loop until we get a response from our request

    my $response = $rpc->request('add', [1,2] );

    $response->on_done(sub{ print "sum is ", @_ });

    $rpc->loop($response);


    # loop 100 times
    $rpc->loop(100);

=head1 SEE ALSO

=over

=item L<MsgPack::RPC::Message>

=item L<MsgPack::RPC::Message::Request>

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
