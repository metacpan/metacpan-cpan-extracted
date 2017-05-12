package Sprocket::Server;

use strict;
use warnings;

use Sprocket qw( Base );
use base qw( Sprocket::Base );
use POE qw(
    Wheel::SocketFactory
    Filter::Stackable
    Filter::Stream
    Driver::SysRW
);
use Socket qw( INADDR_ANY inet_ntoa inet_aton AF_INET AF_UNIX PF_UNIX sockaddr_in );
use Scalar::Util qw( dualvar );

__PACKAGE__->mk_accessors( qw( listen_address listen_port ) );

BEGIN {
    $sprocket->register_hook( [qw(
        sprocket.local.connection.accept
        sprocket.local.connection.reject
        sprocket.local.connection.receive
        sprocket.local.wheel.error
    )] );
}

sub spawn {
    my $class = shift;
   
    my $self = $class->SUPER::spawn(
        $class->SUPER::new(
            @_,
            _type => 'local',
        ),
        qw(
            _startup
            _stop

            local_accept
            local_receive
            local_flushed
            local_wheel_error
            local_error

            accept
            reject
        ),
    );

    return $self;
}

sub check_params {
    my $self = shift;

    $self->{name} ||= 'Server';
    $self->{opts}->{listen_address} ||= INADDR_ANY;
    $self->{opts}->{domain} ||= AF_INET;
    $self->{opts}->{listen_port} = 0
        unless ( defined( $self->{opts}->{listen_port} ) );
    $self->{opts}->{listen_queue} ||= 10000;
    $self->{opts}->{reuse} ||= 'yes';
    
    if ( $self->{opts}->{ssl} ) {
        eval 'use POE::Filter::SSL;';
        if ( $@ ) {
            die "During load of POE::Filter::SSL: $@\n";
        } else {
            $self->_log( v => 2, msg => "SSL is ON for "
                ."$self->{opts}->{listen_address}:$self->{opts}->{listen_port}");
        } 
    }

    return;
}

sub _startup {
    my $self = $_[ OBJECT ];

    # create a socket factory
    $self->{wheel} = POE::Wheel::SocketFactory->new(
        BindPort       => $self->{opts}->{listen_port},
        BindAddress    => $self->{opts}->{listen_address},
        SocketDomain   => $self->{opts}->{domain},
        Reuse          => $self->{opts}->{reuse},
        SuccessEvent   => 'local_accept',
        FailureEvent   => 'local_wheel_error',
        ListenQueue    => $self->{opts}->{listen_queue},
    );

    my ( $port, $ip ) = ( sockaddr_in( $self->{wheel}->getsockname() ) );
    $ip = inet_ntoa( $ip );

    $self->listen_port( $self->{opts}->{listen_port} || $port );
    $self->listen_address( $ip || $self->{opts}->{listen_address} );

    $self->_log( v => 2, msg => sprintf( "Listening to port %d(%d) on %s(%s)",
        $self->{opts}->{listen_port}, $self->listen_port,
        $self->{opts}->{listen_address}, $self->listen_address ) );
}

sub _stop {
    my $self = $_[ OBJECT ];
    $self->_log( v => 2, msg => $self->{name}." stopped.");
}

# Accept a new connection

sub local_accept {
    my ( $self, $socket, $peer_ip, $peer_port ) =
        @_[ OBJECT, ARG0, ARG1, ARG2 ];

    my ( $port, $ip );
    if ( length( $peer_ip ) == 4 ) {
        ( $port, $ip ) = ( sockaddr_in( getsockname( $socket ) ) );
        $peer_ip = inet_ntoa( $peer_ip );
        $ip = inet_ntoa( $ip );
    } else {
        # ipv6
        ( $port, $ip ) = ( Socket6::sockaddr_in6( getsockname( $socket ) ) );
        $peer_ip = Socket6::inet_ntop( $self->{opts}->{domain}, $peer_ip );
        $ip = Socket6::inet_ntop( $self->{opts}->{domain}, $ip );
    }

    my $con = $self->new_connection(
        local_ip => $ip,
        local_port => $port,
        peer_ip => $peer_ip,
        # TODO resolve these?
        peer_hostname => $peer_ip,
        peer_port => $peer_port,
        peer_addr => "$peer_ip:$peer_port",
    );
    
    $con->socket( $socket );

    $self->process_plugins( [ 'local_accept', $self, $con, $socket ] );
    
    return;
}

sub accept {
    my ( $self, $con, $opts ) = @_[ OBJECT, HEAP, ARG0 ];
    
    $opts = {} unless ( $opts );

    $opts->{block_size} ||= 2048;
    $opts->{filter} ||= POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Stream->new(),
        ]
    );
    $opts->{time_out} = $self->{opts}->{time_out}
        unless( defined( $opts->{time_out} ) );

    if ( $self->{opts}->{ssl} ) {
        if ( $opts->{filter}->isa( 'POE::Filter::Stackable' ) || $opts->{filter}->can( 'push' ) ) {
            # TODO use filter push
            eval {
                $opts->{filter} = POE::Filter::Stackable->new(
                    Filters => [
                        POE::Filter::SSL->new(
                            key_file => $self->{opts}->{ssl_key_file},
                            cert_file => $self->{opts}->{ssl_cert_file}
                        )
                    ]
                );
            };
            if ( $@ ) {
                $self->_log( v => 1, msg => "Could not push POE::Filter::SSL on the stack, REJECTING CONNECTION : $@");
                $con->close( 1 );
                return;
            }
            $self->_log( v => 4, msg => "Using SSL");
        } else {
            $self->_log( v => 1, msg => "The filter: $opts->{filter} does not have a push method, or isn't a Stackable Filter. REJECTING CONNECTION");
            $con->close( 1 );
            return;
        }
    }

    my $socket = $con->socket;

    $con->wheel_readwrite(
        Handle          => $socket,
        Driver          => POE::Driver::SysRW->new( BlockSize => $opts->{block_size} ),
        Filter          => $opts->{filter},
        InputEvent      => $con->event( 'local_receive' ),
        ErrorEvent      => $con->event( 'local_error' ),
        FlushedEvent    => $con->event( 'local_flushed' ),
    );

    $con->set_time_out( $opts->{time_out} )
        if ( $opts->{time_out} );
    
    $sprocket->broadcast( 'sprocket.local.connection.accept', {
        source => $self,
        target => $con,
    } );
    
    $con->socket( undef );
    
    $self->process_plugins( [ 'local_connected', $self, $con, $socket ] );

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

sub local_receive {
    my ( $self, $con ) = @_[ OBJECT, HEAP ];
    
    $sprocket->broadcast( 'sprocket.local.connection.receive', {
        source => $self,
        target => $con,
        data => $_[ARG0]
    } );
    
    $self->process_plugins( [ 'local_receive', $self, $con, $_[ARG0] ] );
    
    return;
}

sub local_flushed {
    my ( $self, $con ) = @_[ OBJECT, HEAP ];

    $con->close()
        if ( $con->close_on_flush && not $con->get_driver_out_octets() );

    # If you need this event in your plugin, subclass Sprocket::Server
    
    return;
}

sub local_wheel_error {
    my ( $self, $operation, $errnum, $errstr ) = 
        @_[ OBJECT, ARG0, ARG1, ARG2 ];
    
    $self->_log( v => 1, msg => $self->{name}." encountered $operation error $errnum: $errstr (Server socket wheel)");
    
    $sprocket->broadcast( 'sprocket.local.wheel.error', {
        source => $self,
        operation => $operation,
        errnum => $errnum,
        errstr => $errstr,
    } );
    
    $self->process_plugins( [ 'local_error', $self, $operation, $errnum, $errstr ] );
    
    return;
}

sub local_error {
    my ( $self, $con, $operation, $errnum, $errstr ) = 
        @_[ OBJECT, HEAP, ARG0, ARG1, ARG2 ];
    
    $con->error( dualvar( $errnum, "$operation - $errstr" ) );
    
    # TODO use constant
    $self->_log( v => 3, msg => $self->{name}." encountered $operation error $errnum: $errstr")
        if ( $errnum != 0 );
    
    $self->process_plugins( [ 'local_disconnected', $self, $con, 1, $operation, $errnum, $errstr ] );
    
    $con->close();
    
    return;
}

sub begin_soft_shutdown {
    my $self = $_[ OBJECT ];

    $self->_log( v => 2, msg => $self->{name}." is shuting down (soft)");

    foreach ( values %{$self->{heaps}} ) {
        next unless defined;
        $self->process_plugins( [ 'local_shutdown', $self, $_ ] );
    }

    return;
}

1;

__END__

=head1 NAME

Sprocket::Server - The Sprocket Server

=head1 SYNOPSIS

    use Sprocket qw( Server );
    
    Sprocket::Server->spawn(
        Name => 'Test Server',        # Optional, defaults to Server
        ListenAddress => '127.0.0.1', # Optional, defaults to INADDR_ANY
        ListenPort => 9979,           # Optional, defaults to 0 (random port)
        Domain => AF_INET,            # Optional, defaults to AF_INET
        Reuse => 'yes',               # Optional, defaults to yes
        Plugins => [
            {
                plugin => MyPlugin->new(),
                priority => 0, # default
            },
        ],
        LogLevel => 4,
        MaxConnections => 10000,
    );


=head1 DESCRIPTION

Sprocket::Server defines a TCP/IP Server, it binds to a Address and Port and
listens for incoming TCP/IP connections.

=head1 METHODS

=over 4

=item spawn( %options )

Create a new Sprocket::Server object.

=over 4

=item Name => (str)

The Name for this server. This is used for logging.  It is optional and
defaults to 'Server'

=item ListenPort => (int)

The port this server listens on. 

=item ListenAddress => (str)

The address this server listens on.

=item Domain => (const)

The domain type for the socket.  Defaults to AF_INET.  For UNIX sockets, see
L<Sprocket::Server::UNIX>

=item LogLevel => (int)

The minimum level of logging, defaults to 4

=item Logger => (object)

L<Sprocket::Logger::Basic> is the default and logs to STDERR.  The object
must support put( $server, { v => $level, msg => $msg } ) or wrap a logging
system using this format.  See also L<Sprocket::Logger::Log4perl>

=item MaxConnections => (int)

Sprocket will set the rlimit to this value using L<BSD::Resource>

=item Plugins => (array ref of hash refs)

Plugins that this server will hand off processing to. In an array ref of
hash ref's format as so:

    {
        plugin => MyPlugin->new(),
        priority => 0 # default
    }

=back

=item shutdown( $type )

Shutdown this server. If $type is 'soft' then a soft shutdown procedure will
begin.  local_shutdown will be called for each connection.

=item name

The name of the server, specified during spawn.

=item session_id

Session id of the controlling poe session.

=item uuid

UUID of the server, generated during spawn.

=item shutting_down

returns the shutdown type, ie. 'soft' if shutting down, otherwize, undef.

=item connections

returns the number of connections

=item _logger

returns the logger object.

=item opts

returns a hash ref of the options passed to spawn

=item is_forked

true if the server is pre-forked

=item is_child

true if this instance is a forked process.  You can determine if you're in the
parent process if is_child is false and is_forked is true.

=back

=head1 HOOKS

See L<Sprocket> for observer hook semantics.

=over 4

=item sprocket.local.connection.accept

=item sprocket.local.connection.reject

=item sprocket.local.connection.receive

=item sprocket.local.wheel.error

=back

=head1 EVENTS

These events are handled by plugins.  See L<Sprocket::Plugin>.

=over 4

=item local_accept

=item local_connected

=item local_receive 

=item local_disconnected

=item local_time_out

=item local_error

=item local_shutdown

=back

=head1 SEE ALSO

L<POE>, L<Sprocket>, L<Sprocket::Connection>, L<Sprocket::Plugin>,
L<Sprocket::Client>, L<Sprocket::Server::PreFork>, L<Sprocket::Server::UNIX>,
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

