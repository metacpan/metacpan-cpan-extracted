package Sprocket::Plugin;

use Class::Accessor::Fast;
use base qw(Class::Accessor::Fast);
use Scalar::Util qw( weaken blessed );
use POE;
use Sprocket;
use Sprocket::Local;
use Errno qw( EADDRINUSE );

__PACKAGE__->mk_accessors( qw( uuid _uuid name parent_id ID ) );

use overload '""' => sub { shift->ID() };

use strict;
use warnings;

# Sprocket::Spread import will replace this
# when imported on demand
our $sprocket_spread;

our %plugin_event_list = map { $_ => 1 } qw(
    local_accept
    local_connected
    local_receive
    local_disconnected
    local_time_out
    local_error

    remote_accept
    remote_connected
    remote_receive
    remote_disconnected
    remote_connect_error
    remote_time_out

    plugin_start_aio
    add_plugin
);

our %plugin_event_discon = map { $_ => 1 } qw(
    local_disconnected

    remote_disconnected
    remote_connect_error
);

sub new {
    my $class = shift;
    
    my $self = bless( {
        __conlist__ => {},
        &adjust_params,
    }, ref $class || $class );

    # unique uuid, different for each instance
    $self->uuid( new_uuid() );
    
    $self->ID( $class.'/'.$self->uuid );
    
    # uuid based off of the plugin's ref
    $self->_uuid( gen_uuid( $self ) );

    $sprocket->add_plugin( $self );
    
    return $self;
}

sub handle_event {
    my ( $self, $event ) = ( shift, shift );
    
    delete $self->{__conlist__}->{ $_[ 1 ]->ID }
        if ( $self->{__conlist__} && exists( $plugin_event_discon{ $event } ) );
    
    if ( $self->can( $event ) ) {
        $self->$event( @_ );
    } else {
        $self->_log( v => $self->{log_unhandled_events}, msg => "unhandled plugin event: $event" )
            if ( $self->{log_unhandled_events} && !exists( $plugin_event_list{ $event } ) );
    }
    
    return 1;
}

sub _log {
    $poe_kernel->call( shift->parent_id => _log => ( call => ( caller(1) )[ 3 ], @_ ) );
    return;
}

# ==========================================
# Events
# ==========================================

sub local_accept {
    my ( $self, $server, $con, $socket ) = @_;
    if ( $server->shutting_down ) {
        $con->reject();
    } else {
        $con->accept();
    }
    return;
}

sub local_connected {
    my ( $self, $server, $con, $socket ) = @_;
    $server->_log( v => 4, msg => 'Rejecting connection because plugin:'
        .$self.' did not define a local_connected event' );
    $con->reject();
    return;
}

sub local_error {
    my ( $self, $server, $operation, $errnum, $errstr ) = @_;
    # note that this has no $con, it's a server wheel error
    $server->shutdown() if ( $errnum == EADDRINUSE );
    return;
}

sub local_time_out {
    my ( $self, $server, $con, $time ) = @_;
    $server->_log( v => 4, msg => 'Timeout for connection ' );
    $con->close();
    return;
}

sub local_shutdown {
    my ( $self, $server, $con ) = @_;
    $server->_log( v => 4, msg => 'Closing connection, shutting down' );
    $con->close( 1 );
    return;
}

sub remote_connected {
    my ( $self, $client, $con, $socket ) = @_;
    $client->_log( v => 4, msg => 'Rejecting connection because plugin:'
        .$self.' did not define a remote_connected event' );
    $con->reject();
    return;
}

sub remote_accept {
    my ( $self, $client, $con, $socket ) = @_;
    # XXX shutting_down?
    $con->accept();
    return;
}

sub remote_disconnected {
    my ( $self, $client, $con ) = @_;
    $con->close();
    return;
}

sub remote_connect_error {
    my ( $self, $client, $con, $res_err, $res_obj ) = @_;
    $con->close();
    return;
}

sub remote_time_out {
    my ( $self, $client, $con, $time ) = @_;
    $client->_log( v => 4, msg => 'Timeout for connection' );
    $con->close();
    return;
}

sub remote_shutdown {
    my ( $self, $client, $con ) = @_;
    $client->_log( v => 4, msg => 'Closing connection, shutting down' );
    $con->close( 1 );
    return;
}

# ==========================================
# Methods
# ==========================================

sub get_plugin_connection {
    my ( $self, $server, $id ) = @_;

    # Sprocket::Local singleton
    return $sprocket_local->get_connection( $server, $id );
}

sub take_connection {
    my ( $self, $con ) = @_;
    
    $self->{__conlist__}->{ $con->ID } = 1
        if ( $self->{__conlist__} );
    
    $con->plugin( $self->uuid );
    return;
}

sub release_connection {
    my ( $self, $con ) = @_;
    
    delete $self->{__conlist__}->{ $con->ID }
        if ( $self->{__conlist__} );
    
    $con->plugin( undef );
    return;
}

sub spread_subscribe {
    my ( $self, $groups ) = @_;

    if ( !defined( $sprocket_spread ) ) {
        # XXX is there a better way?
        require Sprocket::Spread;
        import Sprocket::Spread;
    }
    
    $groups = [ $groups ] unless ( ref $groups );

    return $sprocket_spread->plugin_subscribe( $self, $groups );
}

sub spread_unsubscribe {
    my ( $self, $groups ) = @_;

    if ( !defined( $sprocket_spread ) ) {
        # XXX is there a better way?
        require Sprocket::Spread;
        import Sprocket::Spread;
    }
    $groups = [ $groups ] unless ( ref $groups );

    return $sprocket_spread->plugin_unsubscribe( $self, $groups );
}

sub spread_publish {
    my $self = shift;
    my $groups = shift;

    if ( !defined( $sprocket_spread ) ) {
        # XXX is there a better way?
        require Sprocket::Spread;
        import Sprocket::Spread;
    }
    
    $groups = [ $groups ] unless ( ref $groups );

    return $sprocket_spread->plugin_publish( $self, $groups, @_ );
}

sub con_list {
    my $self = shift;
    
    if ( $self->{__conlist__} ) {
        my @ids = keys %{ $self->{__conlist__} };
        return wantarray ? @ids : \@ids;
    }

    return wantarray ? () : [];
}

*con_id_list = *con_list;

1;

__END__

=pod

=head1 NAME

Sprocket::Plugin - Base class for Sprocket plugins

=head1 SYNOPSIS

  use Sprocket qw( Plugin );
  use base qw( Sprocket::Plugin );

  sub new {
      shift->SUPER::new(
          name => 'MyPlugin',
          @_
      );
  }

  sub as_string {
      __PACKAGE__;
  }

  ...

=head1 ABSTRACT

This is a base class for Sprocket plugins.  It provides several default methods
for easy plugin implementation.

=head1 NOTES

A plugin can define any of the methods below.  All are optional, but a plugin
should have a conncted and a receive method for it to function.  See the
Sprocket site for examples.  L<http://sprocket.cc/>  Plugins should use the
template in the SYNOPSIS.

Also, this module is a subclass of L<Class::Accessor::Fast>, so subclasses of 
L<Sprocket::Plugin> can create accessors like so (in your new() method):

  __PACKAGE__->mk_accessors( qw( foo bar baz ) );

=head1 EVENTS

=head2 Server Event Methods

These are methods that can be defined in a plugin for Sprocket server instances

=over 4

=item local_accept

Called with ( $self, $server, $con, $socket )
Defining this method is optional.  The default behavior is to accept the
connection.  You can call $con->reject() or $con->accept() to reject or
accept a connection.  You can also call $self->take_connection( $con );
in this phase.  See L<Sprocket::Connection> for more information on the
accept and reject methods.

=item local_connected

Called with ( $self, $server, $con, $socket )
This is the last chance for a plugin to take a connection with
$self->take_connection( $con );  You should apply your filters for the
connection in this method.  See L<Sprocket::Connection> for details on how
to access the connection's filters.

=item local_receive

Called with ( $self, $server, $con, $data )
$data is the data from the filter applied to the connection.

Note: A connection's active time doesn't update automaticly for this event.
You can call $con->active(), see L<Sprocket::Connection>.

=item local_disconnected

Called with ( $self, $server, $con, $error )
If error is true, then $operation, $errnum, and $errstr will also be defined
after $error.   If a connection was closed with $con->close() then $error
will be false.  If a connection was closed remotely but without an error then
$error will be true, but $errnum will be 0.  For more details, see ErrorEvent
in L<POE::Wheel::ReadWrite>.

=item local_error

Called with ( $self, $server, $operation, $errnum, $errstr )
This is only called when there is an error with the server wheel, like a bind
error. ( $errnum will == EADDRINUSE, after: use Errno qw( EADDRINUSE ); )
The default behavior will be to shutdown the server if there is a bind error.

=item local_time_out

Called with ( $self, $server, $con, $time )
A time out occurred on the connection.  This means the $con->active_time +
$con->time_out is less than $time.  You can choose to $con->close() or not.
The default behavior is to close the connection.  This event will only occur
if you have set a time out with $con->set_time_out( $seconds )

=item local_shutdown

Called with ( $self, $server, $con )
This is currently only called when a soft shutdown is initiated.  You should
make cleanup arrangements and close the connection asap.  The server will wait
for all connections to close.  See the shutdown command in L<Sprocket::Server>,
and L<Sprocket::Client>.

=back

=head2 Client Event Methods

These are methods that can be defined in a plugin for Sprocket client instances

=over 4

=item remote_accept

Why is there an accept method for client connections?!
Well, good question.  This method is here to allow you to set the filters
and blocksize using the $con-accept method.  See L<Sprocket::Connection>

See local_accept.

=item remote_connected

See local_connected.

=item remote_receive

See local_receive.

=item remote_disconnected

See local_disconnected.
You can call $con->reconnect() to attempt to reconnect to the host.

=item remote_connect_error

Called with ( $self, $client, $con )
If a connection wasn't attempted due to a DNS issue, $response_error,
and $response_obj from L<POE::Component::DNS> will follow $con.  The 
remote_disconnected event will not be called. You can call $con->reconnect()
to attempt to reconnect to the host.

=item remote_time_out

Called with ( $self, $client, $con, $time )
A time out occurred on the connection.  This means the $con->active_time +
$con->time_out is less than $time.  You can choose to $con->close() or not.
The default behavior is to close the connection.  This event will only occur
if you have set a time out with $con->set_time_out( $seconds )

=item remote_shutdown

See local_shutdown.

=back

=head1 METHODS

=over 4

=item $self->con_id_list

Returns a list of connection ids currently active conenctions taken by
the plugin.  Use $sprocket->get_connection() to get the connection reference.
Note: con_id_list in a scalar context will return an array ref

  foreach ( $self->con_id_list ) {
      if ( my $con = $sprocket->get_connection( $_ ) ) {
          $con->send( "you are client:".$con->ID );
      }
  }

=item $self->take_connection( $con )

Assigns the connection to your plugin.  Usually done during the accept or
connect phase.

=item release_connection( $con );

=item spread_subscribe( [ 'group1', 'group2' ] );

=item spread_unsubscribe( [ 'group1', 'group2' ] );

=item spread_publish( [ 'group1', 'group2' ], $message, @etc );

=back

=head1 SEE ALSO

L<Sprocket>, L<Sprocket::Connection>, L<Sprocket::AIO>, L<Sprocket::Server>,
L<Sprocket::Client>, L<Sprocket::Local>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

See L<Sprocket> for license information.

=cut
