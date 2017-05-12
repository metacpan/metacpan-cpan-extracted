package Sprocket::Client;

use strict;
use warnings;

use POE qw(
    Filter::Stackable
    Filter::Stream
    Driver::SysRW
    Component::Client::DNS
);
use Sprocket qw( Base );
use base qw( Sprocket::Base );
use Scalar::Util qw( dualvar );

BEGIN {
    $sprocket->register_hook( [qw(
        sprocket.remote.connection.accept
        sprocket.remote.connection.reject
        sprocket.remote.connection.receive
        sprocket.remote.address.resolved
        sprocket.remote.wheel.error
    )] );
}

sub spawn {
    my $class = shift;
    
    my $self = $class->SUPER::spawn(
        $class->SUPER::new(
            @_,
            _type => 'remote'
        ),
        qw(
            _startup
            _stop

            connect
            reconnect
            remote_connect_success
            remote_connect_timeout
            remote_connect_error
            remote_error
            remote_receive
            remote_flushed

            resolved_address

            accept
            reject
        )
    );

    return $self;
}

sub check_params {
    my $self = shift;

    $self->{name} ||= "Client";

    return;
}

sub _startup {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
    
    # XXX ok to doc
    $session->option( @{$self->{opts}->{client_session_options}} )
        if ( $self->{opts}->{client_session_options} );
    
    # XXX don't doc yet
    $kernel->alias_set( $self->{opts}->{client_alias} )
        if ( $self->{opts}->{client_alias} );
    
    # connect to our client list
    foreach ( @{$self->{opts}->{client_list}} ) {
        $self->connect( ref( $_ ) eq 'ARRAY' ? @$_ : $_ );
    }

    return;
}

sub _stop {
    my $self = $_[ OBJECT ];
    $self->_log( v => 2, msg => $self->{name}." stopped.");
}

sub remote_connect_success {
    my ( $kernel, $self, $con, $socket ) = @_[ KERNEL, OBJECT, HEAP, ARG0 ];
    
    $con->peer_addr( $con->peer_ip.':'.$con->peer_port );
    
    $self->_log( v => 3, msg => $self->{name}." connected");

    if ( my $tid = $con->time_out_id ) {
        $kernel->alarm_remove( $tid );
        $con->time_out_id( undef );
    }

    $con->socket( $socket );
    $self->process_plugins( [ 'remote_accept', $self, $con, $socket ] );

    return;
}

sub accept {
    my ( $self, $con, $opts ) = @_[ OBJECT, HEAP, ARG0 ];
    
    $opts = {} unless ( $opts );

    $opts->{block_size} ||= 2048;
    # XXX don't document this yet, we need to be able to set
    # the input and output filters seperately
    $opts->{filter} ||= POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Stream->new(),
        ]
    );
    $opts->{time_out} = $self->{opts}->{time_out}
        unless( defined( $opts->{time_out} ) );

    my $socket = $con->socket;
    
    $con->wheel_readwrite(
        Handle          => $socket,
        Driver          => POE::Driver::SysRW->new( BlockSize => $opts->{block_size} ),
        Filter          => $opts->{filter},
        InputEvent      => $con->event( 'remote_receive' ),
        ErrorEvent      => $con->event( 'remote_error' ),
        FlushedEvent    => $con->event( 'remote_flushed' ),
    );
    
    $sprocket->broadcast( 'sprocket.remote.connection.accept', {
        source => $self,
        target => $con,
    } );
    
    $con->socket( undef );
    
    $self->process_plugins( [ 'remote_connected', $self, $con, $socket ] );

    # nothing took the connection
    unless ( $con->plugin ) {
        $self->_log( v => 2, msg => "No plugin took this connection, Dropping.");
        $con->close();
    }
    
    return;
}

sub reject {
    my ( $self, $con ) = @_[ OBJECT, HEAP ];
    
    $sprocket->broadcast( 'sprocket.remote.connection.reject', {
        source => $self,
        target => $con,
    } );
    
    # XXX other?
    $con->socket( undef );
    $con->close( 1 );
    
    return;
}

sub remote_connect_error {
    my ( $kernel, $self, $con, $operation, $errnum, $errstr ) = 
        @_[ KERNEL, OBJECT, HEAP, ARG0, ARG1, ARG2 ];

    $con->error( dualvar( $errnum, "$operation - $errstr" ) );

    $self->_log( v => 2, msg => $self->{name}." : Error connecting to ".$con->peer_addr
        ." : $operation error $errnum ($errstr)");

    if ( my $tid = $con->time_out_id ) {
        $kernel->alarm_remove( $tid );
        $con->time_out_id( undef );
    }

#    if ( $con->connected ) {
        $self->process_plugins( [ 'remote_disconnected', $self, $con, @_[ ARG0 .. ARG2 ] ] );
#    } else {
#        $self->process_plugins( [ 'remote_connect_error', $self, $con ] );
#    }
    
    return;
}

sub remote_connect_timeout {
    my $self = $_[ OBJECT ];
    
    $self->_log( v => 2, msg => $self->{name}." : timeout while connecting");

    $self->process_plugins( [ 'remote_connect_error', $self, $_[ HEAP ] ] );

    return;
}

sub remote_receive {
    my $self = $_[ OBJECT ];

    $sprocket->broadcast( 'sprocket.remote.connection.receive', {
        source => $self,
        target => $_[ HEAP ],
        data => $_[ ARG0 ],
    } );
    
    $self->process_plugins( [ 'remote_receive', $self, @_[ HEAP, ARG0 ] ] );
    
    return;
}

sub remote_error {
    my ( $self, $con, $operation, $errnum, $errstr ) = 
        @_[ OBJECT, HEAP, ARG0, ARG1, ARG2 ];
    
    $con->error( dualvar( $errnum, "$operation - $errstr" ) );
    
    if ( $errnum != 0 ) {
        $self->_log( v => 3, msg => $self->{name}." encountered $operation error $errnum: $errstr");
    }
    
    $sprocket->broadcast( 'sprocket.remote.wheel.error', {
        source => $self,
        operation => $operation,
        errnum => $errnum,
        errstr => $errstr,
    } );
    
    $self->process_plugins( [ 'remote_disconnected', $self, $con, 1, $operation, $errnum, $errstr ] );
    
    return;
}

sub remote_flushed {
    my ( $self, $con ) = @_[ OBJECT, HEAP ];

    # we'll get called again if there are octets out
    $con->close()
        if ( $con->close_on_flush && not $con->get_driver_out_octets() );
    
    return;
}

sub connect {
    # must call in this in our session's context
    unless ( $_[KERNEL] && ref $_[KERNEL] ) {
        return $poe_kernel->call( shift->{session_id} => connect => @_ );
    }
    
    my ( $self, $kernel, $address, $port ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];
    
    # support an array ref
    ( $address, $port ) = @$address if ( ref( $address ) eq 'ARRAY' );
    
    ( $address, $port ) = ( $address =~ /^([^:]+):(\d+)$/ )
        unless( defined $port );

    return $self->_log( v => 1, msg => 'Port not defined in call to connect, IGNORED. address: '.$address )
        unless ( defined $port );
    
    my $con;

    # PoCo DNS
    # XXX ipv6?!
    if ( $address !~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
        my $named_ses = $kernel->alias_resolve( 'named' );

        # no DNS resolver found, load one instead
        unless ( $named_ses ) {
            # could use the object here, but I don't want
            # duplicated code, so just use the session reference
            POE::Component::Client::DNS->spawn( Alias => 'named' );
            $named_ses = $kernel->alias_resolve( 'named' );
            # release ownership of this session
            #$kernel->detach_child( $named_ses );
        }

        # a new unconnected connection
        $con = $self->new_connection(
            peer_port => $port,
            peer_hostname => $address,
            peer_addr => "$address:$port", # temp until resolved
        );

        $kernel->call( $named_ses => 'resolve' => {
            host => $address,
            context => 1,
            event => $con->event( 'resolved_address' ),
        });

        # we will connect after resolving the address
        return $con;
    } else {
        $con = $self->new_connection(
            peer_ip => $address,
            peer_port => $port,
            peer_addr => "$address:$port",
        );
    }

    return $self->reconnect( $con );
}

sub resolved_address {
    my ( $self, $con, $response ) = @_[ OBJECT, HEAP, ARG0 ];
    
    my ( $response_obj, $response_err ) = @{$response}{qw( response error )};

    unless ( defined $response_obj ) {
        $self->_log( v => 4, msg => 'resolution of '.$con->peer_hostname.' failed: '.$response_err  );
        $self->process_plugins( [ 'remote_connect_error', $self, $con, $response_err, $response_obj ] );
        return;
    }

    my @addr = map { $_->rdatastr } ( $response_obj->answer );
    my $peer_ip = $addr[ int rand( @addr ) ];
    
    $con->peer_ips( \@addr );
    
    # pick a random ip
    $self->_log( v => 4, msg => 'resolved '.$con->peer_hostname.' to '.join(',',@addr).' using: '.$peer_ip );
    
    $con->peer_ip( $peer_ip );
    $con->peer_addr( $peer_ip.':'.$con->peer_port );

    $sprocket->broadcast( 'sprocket.remote.address.resolved', {
        source => $self,
        addresses => \@addr,
        response => $response_obj,
        peer_ip => $peer_ip,
    } );

    $self->reconnect( $con, 1 );

    return;
}

sub reconnect {
    my ( $self, $con, $noclose );
    unless ( $_[KERNEL] && ref $_[KERNEL] ) {
        ( $self, $con ) = ( shift, shift );
        return $poe_kernel->call( $self->{session_id} => $con->event( 'reconnect' ) => @_ );
    }
    
    ( $self, $con, $noclose ) = @_[ OBJECT, HEAP, ARG0 ];

    # XXX include backoff?

    $con->connected( 0 );
    
    # this would force fused connections to shut each other down
    # so $noclose is passed during a reconnect call, post address resolve
    $con->close( 1 ) unless ( $noclose );
    
#    $con->sf( undef );
#    $con->wheel( undef );

    if ( $self->{opts}->{connect_time_out} ) {
        $con->time_out_id(
            $poe_kernel->alarm_set(
                $con->event( 'remote_connect_timeout' ),
                time() + $self->{opts}->{connect_time_out}
            )
        );
    }

    $con->socket_factory(
        RemoteAddress => $con->peer_ip,
        RemotePort    => $con->peer_port,
        SuccessEvent  => $con->event( 'remote_connect_success' ),
        FailureEvent  => $con->event( 'remote_connect_error' ),
    );

    return $con;
}

sub begin_soft_shutdown {
    my $self = $_[ OBJECT ];
    
    $self->_log( v => 2, msg => $self->{name}." is shuting down (soft)");

    foreach ( values %{$self->{heaps}} ) {
        next unless defined;
        $self->process_plugins( [ 'remote_shutdown', $self, $_ ] );
    }
}

1;

__END__

=head1 NAME

Sprocket::Client - The Sprocket Client

=head1 SYNOPSIS

    use Sprocket qw( Client );
    
    Sprocket::Client->spawn(
        Name => 'My Client',      # Optional, defaults to Client
        ClientList => [           # Optional
            '127.0.0.1:9979',
        ],
        Plugins => [
            {
                plugin => MyPlugin->new(),
                priority => 0, # default
            },
        ],
        LogLevel => 4,
    );


=head1 DESCRIPTION

Sprocket::Client defines a TCP/IP Client, initiates a TCP/IP connection with
a server on a given IP and Port

=head1 METHODS

=over 4

=item spawn( %options )

Create a new Sprocket::Client object. 

=over 4

=item Name => (str)

The Name for this server.  This is used for logging.  It is optional and
defaults to 'Client'

=item ClientList => (array ref)

A list of one or more servers to connect to.

=item LogLevel => (int)

The minimum level of logging, defaults to 4.

=item Logger => (object)

L<Sprocket::Logger::Basic> is the default and logs to STDERR.  The object
must support put( $server, { v => $level, msg => $msg } ) or wrap a logging
system using this format.

=item Plugins => (array ref of hash refs)

Plugins that this client will hand off processing to. In an array ref of
hash refs format as so:

    {
        plugin => MyPlugin->new(),
        priority => 0 # default
    }

=item MaxConnections => (int)

Sprocket will set the rlimit to this value using L<BSD::Resource>

=back

=item connect( $address, $port ) or connect( "$address:$port" )

Connect to a remote host.

=item get_connection( $id )

Retrieves a connection by its id.

=item shutdown( $type )

Shutdown this client.  If $type is 'soft' then soft shutdown procedure will
begin.  remote_shutdown will be called for each connection.

=back

=head1 ACCESSORS

=over 4

=item name

The name of the client, specified during spawn.

=item session_id

Session id of the controlling poe session.

=item uuid

UUID of the client, generated during spawn.

=item shutting_down

returns the shutdown type, ie. 'soft' if shutting down, otherwize, undef.

=item connections

returns the number of connections

=item _logger

returns the logger object

=item opts

returns a hash ref of the options passed to spawn

=back

=head1 EVENTS

These events are handled by plugins.  See L<Sprocket::Plugin>.

=over 4

=item remote_accept

=item remote_connected

=item remote_receive

=item remote_disconnected

=item remote_connect_error

=item remote_time_out

=item remote_shutdown

=back

=head1 HOOKS

See L<Sprocket> for observer hook semantics.

=over 4

=item sprocket.remote.connection.accept

=item sprocket.remote.connection.reject

=item sprocket.remote.connection.receive

=item sprocket.remote.address.resolved

=item sprocket.remote.wheel.error

=back

=head1 SEE ALSO

L<POE>, L<Sprocket>, L<Sprocket::Connection>, L<Sprocket::Plugin>,
L<Sprocket::Server>, L<Sprocket::Server::PreFork>, L<Sprocket::Server::UNIX>,
L<Sprocket::Logger::Basic>, L<Sprocket::Logger::Log4perl>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 RATING

Please rate this module.
L<http://cpanratings.perl.org/rate/?distribution=Sprocket>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

See L<Sprocket> for license information.

=cut

