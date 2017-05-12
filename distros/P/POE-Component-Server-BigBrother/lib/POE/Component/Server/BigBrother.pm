# -*- encoding: utf-8; mode: cperl -*-

package POE::Component::Server::BigBrother;

use strict;
use warnings;
use Carp;

#sub POE::Kernel::TRACE_REFCNT () { 1 }
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#sub POE::Kernel::TRACE_DEFAULT  () { 1 }
#sub POE::Kernel::TRACE_SIGNALS ()  { 1 }
#sub POE::Kernel::ASSERT_EVENTS ()  { 1 }

use base qw(POE::Component::Pluggable);
use POE;
use POE::Component::Pluggable::Constants qw(:ALL);
use POE::Component::Server::TCP;
use POE::Filter::BigBrother;
use POE::Filter::Stream;

use Log::Report syntax => 'SHORT';

# use Smart::Comments;

use vars qw($VERSION);

$VERSION='0.08';

#
# constants
#
use constant DATA_TRUNCATED_MESSAGE        => "... DATA TRUNCATED ...";
use constant DATA_TRUNCATED_MESSAGE_LENGTH => length(DATA_TRUNCATED_MESSAGE);

sub spawn {
    my $package = shift;
    my %opts    = @_;
    $opts{ lc $_ } = delete $opts{$_}
      for keys %opts;  # convert opts to lower case
    my $options = delete $opts{options};
    my $self = bless \%opts, $package;

	$self->_pluggable_init(prefix => 'bb_', types => [ 'MESSAGE', 'EVENT' ]);

    # default values
    $self->{time_out}  ||= 30;        # default time_out
    $self->{bind_port} ||= 1984;      # default bind port
    $self->{max_msg_size} ||= 16384;  # default max message size

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                       shutdown   => '_on_shutdown',
                       register   => '_on_register',
                       unregister => '_on_unregister'
                     },
			$self => [
                qw (
                  _start
                  _on_dispatch
                  )
            ],
        ],
        heap => $self,
        ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
                                              )->ID();
    return $self;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _pluggable_event {
	my ($self) = @_;
	### _pluggable_event: @_
	$poe_kernel->post($self->{session_id}, '_dispatch');
}

sub _on_dispatch {
	my ($kernel,$self,$event,@args) = @_[KERNEL,OBJECT,ARG0,ARG1..$#_];
	$self->_dispatch( $event, @args );
	return;	
}

sub _dispatch {
    my ( $self, $event, @args ) = @_;
    ## _dispatch event: $event
	return 1 if $self->_pluggable_process('MESSAGE', $event, \(@args)) == PLUGIN_EAT_ALL;

    my %sessions;

    # concatenate all session wich correspond to the event
    foreach (
            values %{ $self->{events}->{ $self->{_pluggable_prefix} . 'all' } },
            values %{ $self->{events}->{$event} } ) {
        $sessions{$_} = $_;
    }
    $poe_kernel->post( $_, $event, @args ) for values %sessions;
}

sub _start {
    my ( $kernel, $self, $sender ) = @_[ KERNEL, OBJECT, SENDER ];
    $self->{session_id} = $_[SESSION]->ID();
    if ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    } else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    # Adapt to POE::Component::Server::TCP v1.020 new args
    my $poco_tcp_args
      = POE::Component::Server::TCP->VERSION > 1.007 ? "ClientArgs" : "Args";

    ## Create a tcp server that receives BigBrother messages.  It
    ## will be referred to by the name "server_tcp" when necessary.
    ## It listen on port 1984.  It uses POE::Filter::Block to parse
    ## input and format output.
    $self->{listener} =
      POE::Component::Server::TCP->new(
        ( $self->{alias} ? ( Alias => $self->{alias} . '_tcp_listener' ) : () ),
        $poco_tcp_args     => [ self => $self ],
        Address            => $self->{bind_addr},
        Port               => $self->{bind_port},
        Concurrency        => -1,
        Error              => \&_on_tcp_server_error,
        ClientConnected    => \&_on_client_connect,
        ClientDisconnected => \&_on_client_disconnect,
        ClientFilter       => POE::Filter::Stream->new(),
        ClientInput        => \&_on_client_input,
        InlineStates       => { '_conn_alarm' => \&_conn_alarm, },
      );

    return;
}

sub _conn_alarm {
	### _conn_alarm
	$_[KERNEL]->yield('shutdown');
}

# Register some event(s)
sub _on_register {
	my ($kernel, $session, $sender, $self, @events) = @_[KERNEL, SESSION, SENDER, OBJECT, ARG0 .. $#_ ];
	croak 'Not enough arguments' unless @events;

	my $sender_id = $sender->ID();

	foreach my $event (@events) {
		$event = $self->{_pluggable_prefix} . $event unless $event =~ /^_/;
		$self->{events}->{$event}->{$sender_id} = $sender_id;
		$self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
		unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
			# One count for every event
			$kernel->refcount_increment($sender_id, __PACKAGE__);
		}
		$kernel->yield(_dispatch => $self->{_pluggable_prefix} . 'registered', $sender_id);
	}
	return;
}

sub _on_unregister {
    my ( $kernel, $self, $session, $sender, @events ) =
      @_[ KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_ ];

    die "Not enough arguments for unregister event" unless @events;

    my $sender_id = $sender->ID();
    foreach (@events) {
        delete $self->{events}->{$_}->{$sender_id};
        if ( --$self->{sessions}->{$sender_id}->{refcnt} <= 0 ) {
            delete $self->{sessions}->{$sender_id};
            unless ( $session == $sender ) {
                $kernel->refcount_decrement( $sender_id, __PACKAGE__ );
            }
        }
    }
    return;
}

sub _unregister_sessions {
  my $self = shift;
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     my $refcnt = $self->{sessions}->{$session_id}->{refcnt};
     while ( $refcnt --> 0 ) {
		 $poe_kernel->refcount_decrement($session_id, __PACKAGE__);
     }
     delete $self->{sessions}->{$session_id};
  }
}

sub _on_shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  ### Shutting down BigBrother Gateway
  $self->_unregister_sessions();
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->post( $self->{listener}, 'shutdown' ) if $self->{listener};
  $self->_pluggable_destroy();
  ### Waiting all clients to disconnect
  return;
}

sub _on_tcp_server_error {
	my ($syscall_name, $error_number, $error_string) = @_[ARG0, ARG1, ARG2];
	croak "BigBrother Gateway: $syscall_name error because $error_string\n";
}

sub _on_client_connect {
	my ($kernel, $sender, $heap) = @_ [ KERNEL, SESSION, HEAP ];
	my %args;
	if ( ref $_[ARG0] eq 'HASH' ) {
		%args = %{ $_[ARG0] };
	} elsif ( ref $_[ARG0] eq 'ARRAY' ) {
		%args = @{ $_[ARG0] };
	} else {
		%args = @_[ARG0..$#_];
	}
	my $self = delete $args{self};
	$heap->{bb_server} = $self; # store self object on the client session as server
    $heap->{buffer}  = '';
	_delay_timeout($kernel, $self);
}

sub _on_client_input {
    # Accumulate datas
    $_[HEAP]->{buffer} .= $_[ARG0];
}

sub _decode_bb_message {
    my ($self, $input) = @_;
    my $message = undef;
    my $input_length = length($input);

    if ( $input_length > $self->{max_msg_size} ) {
        print STDERR "Truncated too long BigBrother message ($input_length > ",
          $self->{max_msg_size} . "):\n", substr( $input, 0, 80 ), "\n";
        my $pos = $self->{max_msg_size} - DATA_TRUNCATED_MESSAGE_LENGTH;
        substr( $input, $pos, $input_length - $pos, DATA_TRUNCATED_MESSAGE );
    }

    if (
        $input =~ m/^
                    ((?:(?:(?:dis|en)abl|pag)e|status)) # the command ($1)
                    (\+\d+)? 		# the offset ($2)
                    \s+				# some spaces
                    (\S+?)\.(\S+)	# server.probe ($3, $4)
                    \s+ 			# some spaces
                    (.*)$ 			# last args ($5)
                   /sx
      ) {
        my $command = lc($1);
        $message->{command}   = $command;
        $message->{offset}    = $2 if defined $2;
        $message->{host_name} = $3;
        $message->{probe}     = $4;
        my $args 			  = $5;

        $message->{host_name} =~ tr/,/./;    # Translate server fqdn

        if ( $command eq 'enable' ) {    # Enable command
            $message->{data} = $args;
        } else {
            my ( $arg1, $arg2 ) = split( /\s+/, $args, 2 );
            if ( $command eq 'status' or $command eq 'page' ) {
                $message->{color} = $arg1;
            }
			else {   # Disable command
                $message->{period} = $arg1;
            }
            $message->{data} = $arg2;
        }
    } elsif ($input =~ m/^(?:event\s+)(.+)$/si) {
		$message = { command => 'event', params => $1 };
    } else {
        warning "Unknown BB message: ".substr($input,0,80);
    }

    return $message;
}

sub _on_client_disconnect {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # Remove all alarms
    $kernel->alarm_remove_all();

    # Check if we have receive some datas
    if (length $heap->{buffer}) {
        # Create a new filter to parse raw BB messages
        my $filter = POE::Filter::BigBrother->new();
        my $bb_server = $heap->{bb_server};
        # Decode any BB messages
        foreach my $cooked_input ( @{ $filter->get( [ $heap->{buffer} ] ) } ) {
            if ( my $message = $bb_server->_decode_bb_message($cooked_input) ) {
                $bb_server->_dispatch(
                          $bb_server->{_pluggable_prefix} . $message->{command},
                          $message, $bb_server );
            }
        }
    }
}

sub _delay_timeout {
	my ($kernel,$self) = @_;
	$kernel->delay( '_conn_alarm', $self->{time_out} );
}

sub session_id {
	my ($self) = @_;
	return $self->{session_id};
}

1; # End of POE::Component::Server::BigBrother
__END__

=head1 NAME

POE::Component::Server::BigBrother - POE Component that implements BigBrother daemon functionality

=head1 SYNOPSIS

 use strict;
 use POE;
 use POE::Component::Server::BigBrother;

 POE::Component::Server::BigBrother->spawn(
     alias => 'BigBrother_Server',
     msg_max_size => 8192,
 );

 POE::Session->create(
     package_states => [
       'main' => { 'bb_status' => '_message' },
       'main' => [ qw ( _start ) ] ],
 );

 $poe_kernel->run();

 exit 0;

 sub _start {
   # Our session starts, register to receive all events from poco-BigBrother
   $poe_kernel->post ( 'BigBrother_Server', 'register', qw( all ) );
   return;
 }

 sub _message {
   my ($sender, $message, $bb_server) = @_[SENDER, ARG0, ARG1];
   print $message->{command}," message from ",$message->{host_name},$/;
 }

=head1 DESCRIPTION

POE::Component::Server::BigBrother is a L<POE> component that implements C<BigBrother daemon> functionality.
This is the daemon program that accepts service check information from remote machines.

The component implements the network handling of accepting service check information from
multiple clients.

It is based in part on code shamelessly borrowed from L<POE::Component::IRC>

=head1 CONSTRUCTOR

=over

=item spawn

Optional parameters:

  'alias', set an alias on the component;
  'bind_addr', specify an address to listen on, default is INADDR_ANY;
  'bind_port', specify a port to listen on, default is 1984;
  'time_out', specify a time out in seconds for socket connections, default is 30;
  'max_msg_size', specify the max size for a message, default is 16384;

Returns a POE::Component::Server::BigBrother object.

=back

=head1 METHODS

=over

=item session_id

Takes no arguments. Returns the L<POE::Session> ID of the component. Ideal for posting events to the component.

=item shutdown

Terminates the component. Shuts down the listener and unregisters registered sessions.

=back

=head1 INPUT EVENTS

These are events from other POE sessions that our component will handle:

=head2 C<register>

=over

This will register the sending session.
Takes N arguments: a list of event names that your session wants to
listen for, minus the 'bb_' prefix. So, for instance, if you just
want a program that keeps track of status messages, you'll need to
listen for status. You'd tell POE::Component::Server::BigBrother that
you want those events by saying this:

 $poe_kernel->post ( 'BigBrother_Server', 'register', qw( status ) );

Registering for C<'all'> will cause it to send all BigBrother-related
events to you; this is the easiest way to handle it.

The component will increment the refcount of the calling session to make sure it hangs around for events.
Therefore, you should use either C<unregister> or C<shutdown> to terminate registered sessions.

=back

=head2 C<unregister>

=over

Takes N arguments: a list of event names which you I<don't> want to
receive. If you've previously done a L<C<register>|/"register">
for a particular event which you no longer care about, this event will
tell the BigBrother connection to stop sending them to you. (If you haven't, it just
ignores you..)

If you have registered with 'all', attempting to unregister individual
events such as 'status', etc. will not work. This is a 'feature'.

=back

=head2 C<shutdown>

=over

By default, POE::Component::Server::BigBrother sessions never go away.
If you send a shutdown event it's terminates the component, shuts down the listener and unregisters registered sessions.

=back

=head1 OUTPUT EVENTS

The events you will receive (or can ask to receive) from your running
BigBrother component. Note that all incoming event names your session will
receive are prefixed by 'bb_', to inhibit event namespace pollution.

If you wish, you can ask the server to send you every event it
generates. Simply register for the event name C<'all'>. This is a lot
easier than writing a huge list of things you specifically want to
listen for.

In your event handlers, C<$_[SENDER]> is the particular component session that
sent you the event.

=head2 C<standard events>

All the standard events are sent with the following parameters:

=over

=item ARG0

ARG0 will contain a hashref with the following key/values:

 'command', the type of the message (eg: status, page, etc...);
 'offset', the offset for the command;
 'host_name', the hostname for which the message is applicable;
 'probe', the name of the probe for which the message is applicable;
 'color', the result color of the check (applicable only for status & page messages);
 'data', datas associated with the message;

=item ARG1

ARG1 will contain the POE::Component::Server::BigBrother's object.
Useful if you want on-the-fly access to the object and its methods.

=back

=head3 C<bb_status>

This events are generated upon receipt of status messages.

=head3 C<bb_page>

This events are generated upon receipt of page messages.

=head3 C<bb_enable>

This events are generated upon receipt of enable messages.

=head3 C<bb_disable>

This events are generated upon receipt of disable messages.

=head3 C<bb_event>

This events are generated upon receipt of event messages.

=head1 AUTHOR

Yves Blusseau <yblusseau@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-POE-Component-Server-BigBrother at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Server-BigBrother>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Yves Blusseau. All rights reserved.

POE::Component::Server::BigBrother is free software; you may use, redistribute,
and/or modify it under the same terms as Perl itself.

=cut
