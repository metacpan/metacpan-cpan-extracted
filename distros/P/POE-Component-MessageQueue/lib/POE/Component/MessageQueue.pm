#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue;
use Moose;

our $VERSION = '0.3003'; # VERSION

use POE 0.38;
use POE::Component::Server::Stomp;
use POE::Component::MessageQueue::Client;
use POE::Component::MessageQueue::Queue;
use POE::Component::MessageQueue::Topic;
use POE::Component::MessageQueue::Message;
use POE::Component::MessageQueue::IDGenerator::UUID;
use Net::Stomp;
use Event::Notify;

use constant SHUTDOWN_SIGNALS => ('TERM', 'HUP', 'INT');

has alias => (
	is      => 'ro',
	default => 'MQ',
);

sub master_alias { $_[0]->alias.'-master' }

has logger => (
	is      => 'ro',
	lazy    => 1,
	default => sub {
		my $self = shift;
		POE::Component::MessageQueue::Logger->new(
			logger_alias => $self->logger_alias
		);
	},
	handles => [qw(log)],
);

has notifier => (
	is => 'ro',
	default => sub { Event::Notify->new() },
	handles => [qw(notify register_event unregister_event)],
);

has idgen => (
	is => 'ro',
	default => sub { POE::Component::MessageQueue::IDGenerator::UUID->new() },
	handles => { generate_id => 'generate' },
);

has observers    => (is => 'ro');
has logger_alias => (is => 'ro');

has storage => (
	is       => 'ro', 
	does     => 'POE::Component::MessageQueue::Storage',
	required => 1,
);

has clients => (
	isa       => 'HashRef[POE::Component::MessageQueue::Client]',
	default   => sub { {} },
	traits  => ['Hash'],
	handles => {
		'get_client'     => 'get',
		'remove_client'  => 'delete',
		'set_client'     => 'set',
		'all_client_ids' => 'keys',
	}
);

has shutdown_count => (
	is      => 'ro',
	isa     => 'Num',
	default => 0,
	traits  => ['Counter'],
	handles => {
		'inc_shutdown_count'   => 'inc',
		'dec_shutdown_count'   => 'dec',
		'reset_shutdown_count' => 'reset',
	}
);

has message_class => (
	is      => 'ro',
	isa     => 'ClassName',
	default => 'POE::Component::MessageQueue::Message',
);

has pump_frequency => (
	is      => 'ro',
	isa     => 'Maybe[Num]',
	default => 0,
);

before remove_client => sub {
	my ($self, @ids) = @_;

	if (my @clients = grep { $_ } map { $self->get_client($_) } @ids)
	{
		my $client_str = @clients > 1 
			? 'clients (' . join(', ', map { $_->id } @clients) . ')'
			: 'client ' . $clients[0]->id;

		$self->log(notice => "MASTER: Removing $client_str");

		foreach my $c (@clients)
		{
			my @destinations = map { $_->destination } $c->all_subscriptions;

			$c->unsubscribe($_) foreach @destinations;

			if ($self->shutdown_count == 0)
			{
				$self->storage->disown_all($c->id, 
					sub { $_->pump() foreach @destinations });
			}

			$c->shutdown();
		}
	}
};
	
has destinations => (
	isa     => 'HashRef[POE::Component::MessageQueue::Destination]',
	default => sub { {} },
	traits  => ['Hash'],
	handles => {
		'get_destination'  => 'get',
		'set_destination'  => 'set',
		'all_destinations' => 'values',
	}
);

has owners => (
	isa     => 'HashRef[POE::Component::MessageQueue::Subscription]',
	default => sub { {} },
	traits  => ['Hash'],
	handles => {
		'get_owner'    => 'get',
		'set_owner'    => 'set',
		'delete_owner' => 'delete',
	},
);

sub BUILD
{
	my ($self, $args) = @_;

	my $observers = $self->observers;
	if ($observers) 
	{
		$_->register($self) for (@$observers);
	}

	$self->storage->set_logger($self->logger);

	POE::Component::Server::Stomp->new(
		Alias    => $self->alias,
		Address  => $args->{address},
		Hostname => $args->{hostname},
		Port     => $args->{port},
		Domain   => $args->{domain},

		HandleFrame        => sub { $self->_handle_frame(@_) },
		ClientDisconnected => sub { $self->_client_disconnected(@_) },
		ClientError        => sub { $self->_client_error(@_) },
	);

	# a custom session for non-STOMP responsive tasks
	POE::Session->create(
		object_states => [ $self => [qw(_start _shutdown)] ],
	);
}

sub _start
{
	my ($self, $kernel) = @_[OBJECT, KERNEL ];
	$kernel->alias_set($self->master_alias);

	# install signal handlers to initiate graceful shutdown.
	# We only respond to user-type signals - crash signals like 
	# SEGV and BUS should behave normally
	foreach my $signal ( SHUTDOWN_SIGNALS )
	{
		$kernel->sig($signal => '_shutdown'); 
	}
}

sub make_destination
{
	my ($self, $name) = @_;
	my @args = (name => $name, parent => $self);
	my $dest;

	if ($name =~ m{/queue/})
	{
		$dest = POE::Component::MessageQueue::Queue->new(@args);
	}
	elsif ($name =~ m{/topic/})
	{
		$dest = POE::Component::MessageQueue::Topic->new(@args);
	}

	$self->set_destination($name => $dest) if $dest;
	return $dest;
}

sub _handle_frame
{
	my $self = shift;
	my ($kernel, $heap, $frame) = @_[ KERNEL, HEAP, ARG0 ];

	if ($self->shutdown_count)
	{
		$kernel->yield('shutdown');
		return;
	}

	my $id = $kernel->get_active_session()->ID();

	my $client = $self->get_client($id);
	unless ($client)
	{
		$client = POE::Component::MessageQueue::Client->new(id => $id);
		$self->set_client($id => $client);
	}

	$self->route_frame($client, $frame);
}

sub _client_disconnected
{
	my $self = shift;
	my ($kernel, $heap) = @_[ KERNEL, HEAP ];

	my $id = $kernel->get_active_session()->ID();
	$self->remove_client($id);
}

sub _client_error
{
	my $self = shift;
	my ($kernel, $name, $number, $message) = @_[ KERNEL, ARG0, ARG1, ARG2 ];

	unless ( $name eq 'read' and $number == 0 ) # Anything but EOF
	{
		$self->log(error => "Client error: $name $number $message" );
	}
}

sub _shutdown_complete
{
	my ($self) = @_;

	$self->log('alert', 'Storage engine has finished shutting down');

	# Really, really take us down!
	$self->log('alert', 'Sending TERM signal to master sessions');
	$poe_kernel->signal( $self->alias, 'TERM' );
	$poe_kernel->signal( $self->master_alias, 'TERM' );

	$self->log(alert => 'Shutting down all observers');
	if (my $oref = $self->observers)
	{
		$_->shutdown() foreach (@$oref);
	}

	$self->log(alert => 'Shutting down the logger');
	$self->logger->shutdown();
}

sub route_frame
{
	my ($self, $client, $frame) = @_;
	my $cid = $client->id;
	my $destination_name = $frame->headers->{destination};

	my %handlers = (
		CONNECT => sub {
			my $login    = $frame->headers->{login}    || q();
			my $passcode = $frame->headers->{passcode} || q();

			$self->log('notice', "RECV ($cid): CONNECT $login:$passcode");
			$client->connect($login, $passcode);
		},

		DISCONNECT => sub {
			$self->log( 'notice', "RECV ($cid): DISCONNECT");
			$self->remove_client($cid);
		},

		SEND => sub {
			$frame->headers->{'message-id'} ||= $self->generate_id();
			my $message = $self->message_class->from_stomp_frame($frame);

			if ($message->has_delay() and not $self->pump_frequency)
			{
				$message->clear_delay();

				$self->log(warning => "MASTER: Received a message with deliver-after header, but there is no pump-frequency enabled.  Ignoring header and delivering with no delay.");
			}

			$self->log(notice => 
				sprintf('RECV (%s): SEND message %s (%i bytes) to %s (persistent: %i)',
					$cid, $message->id, $message->size, $message->destination,
					$message->persistent));


			if(my $d = $self->get_destination ($destination_name) ||
			           $self->make_destination($destination_name))
			{
				$self->notify( 'recv', {
					destination => $d,
					message     => $message,
					client      => $client,
				});
				$d->send($message);
			}
			else
			{
				$self->log(error => "Don't know how to send to $destination_name");
			}
		},

		SUBSCRIBE => sub {
			my $ack_type = $frame->headers->{ack};

			$self->log('notice',
				"RECV ($cid): SUBSCRIBE $destination_name (ack: $ack_type)");

			if(my $d = $self->get_destination ($destination_name) ||
			           $self->make_destination($destination_name))
			{
				$client->subscribe($d, $ack_type && $ack_type eq 'client');
				$self->notify(subscribe => {destination => $d, client => $client});
				$d->pump();
			}
			else
			{
				$self->log(error => "Don't know how to subscribe to $destination_name");
			}
		},

		UNSUBSCRIBE => sub {
			$self->log('notice', "RECV ($cid): UNSUBSCRIBE $destination_name");
			if(my $d = $self->get_destination($destination_name))
			{
				$client->unsubscribe($d);
				$self->storage->disown_destination($d->name, $client->id, 
					sub { $d->pump() });
			}
		},

		ACK => sub {
			my $message_id = $frame->headers->{'message-id'};
			$self->log('notice', "RECV ($cid): ACK - message $message_id");
			$self->ack_message($client, $message_id);
		},
	);

	if (my $fn = $handlers{$frame->command})
	{
		# Send receipt on anything but a connect
		if ($frame->command ne 'CONNECT' && 
				$frame->headers && 
				(my $receipt = $frame->headers->{receipt}))
		{
			$client->send_frame(Net::Stomp::Frame->new({
				command => 'RECEIPT',
				headers => {'receipt-id' => $receipt},
			}));
		}
		$fn->();
	}
	else
	{
		$self->log('error', 
			"ERROR: Don't know how to handle frame: " . $frame->as_string);
	}
}

sub ack_message
{
	my ($self, $client, $message_id) = @_;
	my $client_id = $client->id;

	my $s = $self->get_owner($message_id);
	if ($s && $s->client && $s->client->id eq $client_id)
	{
		$self->delete_owner($message_id);
		$s->ready(1);
		my $d = $s->destination;
		$self->notify(remove => $message_id);
		$self->storage->remove($message_id, sub {$d->pump()});
	}
	else
	{
		$self->log(alert => "DANGER: Client $client_id trying to ACK message ".
			"$message_id, which he does not own!");
		return;
	}
}

sub _shutdown 
{
	my ($self, $kernel, $signal) = @_[ OBJECT, KERNEL, ARG0 ];
	$self->log('alert', "Got SIG$signal. Shutting down.");
	$kernel->sig_handled();
	$self->shutdown(); 
}

sub shutdown
{
	my $self = shift;
	$self->inc_shutdown_count;
	if ($self->shutdown_count > 1) 
	{
		if ($self->shutdown_count > 2) 
		{
			# If we handle three shutdown signals, we'll just die.  This is handy
			# during debugging, and no one who wants MQ to shutdown gracefully will
			# throw 3 kills at us.  TODO:  Make sure that's true.
			my $msg = 'Shutdown called ' . $self->shutdown_count 
				. ' times! Forcing ungraceful quit.';
			$self->log('emergency', $msg);
			print STDERR "$msg\n";
			$poe_kernel->stop();
		}
	}
	else 
	{
		# First time we were called, so shut things down.
		$self->log(alert => 'Initiating message queue shutdown...');

		$self->log(alert => 'Shutting down all destinations');
		$_->shutdown() foreach $self->all_destinations;

		# stop listening for connections
		$poe_kernel->post( $self->alias => 'shutdown' );

		# shutdown all client connections
		$self->remove_client( $self->all_client_ids );

		# shutdown the storage
		$self->storage->storage_shutdown( sub { $self->_shutdown_complete(@_) } );
	}
}

sub dispatch_message
{
	my ($self, $msg, $subscriber) = @_;
	return if ($self->shutdown_count > 0);

	my $msg_id = $msg->id;
	my $destination = $self->get_destination($msg->destination);

	if(my $client = $subscriber->client)
	{
		my $client_id = $client->id;
		if ($client->send_frame($msg->create_stomp_frame()))
		{
			$self->log(info => "Dispatching message $msg_id to client $client_id");
			if ($subscriber->client_ack)
			{
				$subscriber->ready(0);
				$self->set_owner($msg_id => $subscriber);
			}
			else
			{
				$self->notify(remove => $msg_id);
				$self->storage->remove($msg_id);
			}

			$self->notify(dispatch => {
				destination => $destination, 
				message     => $msg, 
				client      => $client,
			});
		}
		else
		{
			$self->log(warning => 
				"MASTER: Couldn't send frame to client $client_id: removing.");
			$self->remove_client($client_id);
		}
	}
	else
	{
		$self->log(warning => 
			"MASTER: Message $msg_id could not be delivered (no client)");
		if ($msg->claimed)
		{
			$self->storage->disown_all($msg->claimant, 
				sub { $destination->pump() });
		}
	}
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue - A STOMP based message queue server

=head1 USAGE

If you are only interested in running with the recommended storage backend and
some predetermined defaults, you can use the included command line script:

  POE::Component::MessageQueue version 0.2.12
  Copyright 2007-2011 David Snopek (http://www.hackyourlife.org)
  Copyright 2007, 2008 Paul Driver <frodwith@gmail.com>
  Copyright 2007 Daisuke Maki <daisuke@endeworks.jp>

  mq.pl [--port|-p <num>]               [--hostname|-h <host>]
        [--front-store <str>]           [--front-max <size>] 
        [--granularity <seconds>]       [--nouuids]
        [--timeout|-i <seconds>]        [--throttle|-T <count>]
		[--dbi-dsn <str>]               [--mq-id <str>]
		[--dbi-username <str>]          [--dbi-password <str>]
        [--pump-freq|-Q <seconds>]
        [--data-dir <path_to_dir>]      [--log-conf <path_to_file>]
        [--stats-interval|-i <seconds>] [--stats]
        [--pidfile|-p <path_to_file>]   [--background|-b]
        [--crash-cmd <path_to_script>]
        [--debug-shell] [--version|-v]  [--help|-h]

  SERVER OPTIONS:
    --port     -p <num>     The port number to listen on (Default: 61613)
    --hostname -h <host>    The hostname of the interface to listen on 
                            (Default: localhost)

  STORAGE OPTIONS:
    --storage <str>         Specify which overall storage engine to use.  This
                            affects what other options are value.  (can be
                            default or dbi)
    --front-store -f <str>  Specify which in-memory storage engine to use for
                            the front-store (can be memory or bigmemory).
    --front-max <size>      How much message body the front-store should cache.
                            This size is specified in "human-readable" format
                            as per the -h option of ls, du, etc. (ex. 2.5M)
    --timeout -i <secs>     The number of seconds to keep messages in the 
                            front-store (Default: 4)
    --pump-freq -Q <secs>   How often (in seconds) to automatically pump each
                            queue.  Set to zero to disable this timer entirely
                            (Default: 0)
    --granularity <secs>    How often (in seconds) Complex should check for
                            messages that have passed the timeout.  
    --[no]uuids             Use (or do not use) UUIDs instead of incrementing
                            integers for message IDs.  (Default: uuids)
    --throttle -T <count>   The number of messages that can be stored at once 
                            before throttling (Default: 2)
    --data-dir <path>       The path to the directory to store data 
                            (Default: /var/lib/perl_mq)
    --log-conf <path>       The path to the log configuration file 
                            (Default: /etc/perl_mq/log.conf)

    --dbi-dsn <str>         The database DSN when using --storage dbi
    --dbi-username <str>    The database username when using --storage dbi
    --dbi-password <str>    The database password when using --storage dbi
    --mq-id <str>           A string uniquely identifying this MQ when more
                            than one MQ use the DBI database for storage

  STATISTICS OPTIONS:
    --stats                 If specified the, statistics information will be 
                            written to $DATA_DIR/stats.yml
    --stats-interval <secs> Specifies the number of seconds to wait before 
                            dumping statistics (Default: 10)

  DAEMON OPTIONS:
    --background -b         If specified the script will daemonize and run in the
                            background
    --pidfile    -p <path>  The path to a file to store the PID of the process

    --crash-cmd  <path>     The path to a script to call when crashing.
                            A stacktrace will be printed to the script's STDIN.
                            (ex. 'mail root@localhost')

  OTHER OPTIONS:
    --debug-shell           Run with POE::Component::DebugShell
    --version    -v         Show the current version.
    --help       -h         Show this usage message

=head1 SYNOPSIS

=head2 Subscriber

  use Net::Stomp;
  
  my $stomp = Net::Stomp->new({
    hostname => 'localhost',
    port     => 61613
  });
  
  # Currently, PoCo::MQ doesn't do any authentication, so you can put
  # whatever you want as the login and passcode.
  $stomp->connect({ login => $USERNAME, passcode => $PASSWORD });
  
  $stomp->subscribe({
    destination => '/queue/my_queue.sub_queue',
    ack         => 'client'
  });
  
  while (1)
  {
    my $frame = $stomp->receive_frame;
    print $frame->body . "\n";
    $stomp->ack({ frame => $frame });
  }
  
  $stomp->disconnect();

=head2 Producer

  use Net::Stomp;
  
  my $stomp = Net::Stomp->new({
    hostname => 'localhost',
    port     => 61613
  });
  
  # Currently, PoCo::MQ doesn't do any authentication, so you can put
  # whatever you want as the login and passcode.
  $stomp->connect({ login => $USERNAME, passcode => $PASSWORD });
  
  $stomp->send({
    destination => '/queue/my_queue.sub_queue',
    body        => 'I am a message',
    persistent  => 'true',
  });
  
  $stomp->disconnect();

=head2 Server

If you want to use a different arrangement of storage engines or to embed PoCo::MQ
inside another application, the following synopsis may be useful to you:

  use POE;
  use POE::Component::Logger;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::Default;
  use Socket; # For AF_INET
  use strict;

  my $DATA_DIR = '/tmp/perl_mq';

  # we create a logger, because a production message queue would
  # really need one.
  POE::Component::Logger->spawn(
    ConfigFile => 'log.conf',
    Alias      => 'mq_logger'
  );

  POE::Component::MessageQueue->new({
    port     => 61613,            # Optional.
    address  => '127.0.0.1',      # Optional.
    hostname => 'localhost',      # Optional.
    domain   => AF_INET,          # Optional.
    
    logger_alias => 'mq_logger',  # Optional.

    # Required!!
    storage => POE::Component::MessageQueue::Storage::Default->new({
      data_dir     => $DATA_DIR,
      timeout      => 2,
      throttle_max => 2
    })
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

This module implements a message queue [1] on top of L<POE> that communicates
via the STOMP protocol [2].

There exist a few good Open Source message queues, most notably ActiveMQ [3] which
is written in Java.  It provides more features and flexibility than this one (while
still implementing the STOMP protocol), however, it was (at the time I last used it)
very unstable.  With every version there was a different mix of memory leaks, persistence
problems, STOMP bugs, and file descriptor leaks.  Due to its complexity I was
unable to be very helpful in fixing any of these problems, so I wrote this module!

This component distinguishes itself in a number of ways:

=over 4

=item *

No OS threads, its asynchronous.  (Thanks to L<POE>!)

=item *

Persistence was a high priority.

=item *

A strong effort is put to low memory and high performance.

=item *

Message storage can be provided by a number of different backends.

=item *

Features to support high-availability and fail-over.  (See the L<#HIGH AVAILABILITY> section below)

=back

=head2 Special STOMP headers

You can see the main STOMP documentation here: L<http://stomp.codehaus.org/Protocol>

PoCo::MQ implements a number of non-standard STOMP headers:

=over 4

=item B<persistent>

Set to the string "true" to request that a message be persisted.  Not setting this header
or setting it to any other value, means that a message is non-persistent.

Many storage engines ignore the "persistent" header, either persisting all messages or 
no messages, so be sure to check the documentation for your storage engine.

Using the Complex or Default storage engines, persistent messages will always be sent
to the back store and non-persistent messages will be discarded eventually.

=item B<expire-after>

For non-persistent messages, you can set this header to the number of seconds this
message must be kept before being discarded.  This is ignored for persistent messages.

Many storage engines ignore the "expire-after" header, so be sure to check the
documentation for your storage engine.

Using the Complex or Default storage engines, this header will be honored.  If it isn't
specified, non-persistent messages are discarded when pushed out of the front store.

=item B<deliver-after>

For both persistent or non-persistent messages, you can set this header to the number of
seconds this message should be held before being delivered.  In other words, this allows
you to delay delivery of a message for an arbitrary number of seconds.

All the storage engines in the standard distribution support this header.  B<But it will not
work without a pump frequency enabled!>  If using mq.pl, enable with --pump-freq or if creating
a L<POE::Component::MessageQueue> object directly, pass pump_frequency as an argument to new().

=back

=head2 Queues and Topics

In PoCo::MQ there are two types of I<destinations>: B<queues> and B<topics>

=over 4

=item B<queue>

Each message is only delivered to a single subscriber (not counting
messages that were delivered but not ACK'd).  If there are multiple
subscribers on a single queue, the messages will be divided amoung them,
roughly equally.

=item B<topic>

Each message is delivered to every subscriber.  Topics don't support any kind
of persistence, so to get a message, a subscriber I<must> be connected at the
time it was sent.

=back

All destination names start with either "/queue/" or "/topic/" to distinguish
between queues and topics.

=head2 Tips and Tricks

=over 4

=item B<Logging!  Use it.>

PoCo::MQ uses L<POE::Component::Logger> for logging which is based on
L<Log::Dispatch>.  By default B<mq.pl> looks for a log file at:
"/etc/perl_mq/log.conf".  Or you can specify an alternate location with the
I<--log-conf> command line argument.  

=item B<Using the login/passcode to track clients in the log.>

Currently the login and passcode aren't used by PoCo::MQ for auth, but they
I<are> written to the log file.  In the log file clients are only identified
by the client id.  But if you put information identifying the client in the
login/passcode you can connect that to a client id by finding it in the log.

=back

=head1 STORAGE

When creating an instance of this component you must pass in a storage object
so that the message queue knows how to store its messages.  There are some storage
backends provided with this distribution.  See their individual documentation for 
usage information.  Here is a quick break down:

=over 4

=item *

L<POE::Component::MessageQueue::Storage::Memory> -- The simplest storage engine.  It keeps messages in memory and provides absolutely no presistence.

=item *

L<POE::Component::MessageQueue::Storage::BigMemory> -- An alternative memory storage engine that is optimized for large numbers of messages.

=item *

L<POE::Component::MessageQueue::Storage::DBI> -- Uses Perl L<DBI> to store messages.  Depending on your database configuration, using directly may not be recommended because the message bodies are stored in the database.  Wrapping with L<POE::Component::MessageQueue::Storage::FileSystem> allows you to store the message bodies on disk.  All messages are stored persistently.  (Underneath this is really just L<POE::Component::MessageQueue::Storage::Generic> and L<POE::Component::MessageQueue::Storage::Generic::DBI>)

=item *

L<POE::Component::MessageQueue::Storage::FileSystem> -- Wraps around another storage engine to store the message bodies on the filesystem.  This can be used in conjunction with the DBI storage engine so that message properties are stored in DBI, but the message bodies are stored on disk.  All messages are stored persistently regardless of whether a message has set the persistent header or not.

=item *

L<POE::Component::MessageQueue::Storage::Generic> -- Uses L<POE::Component::Generic> to wrap storage modules that aren't asynchronous.  Using this module is the easiest way to write custom storage engines.

=item *

L<POE::Component::MessageQueue::Storage::Generic::DBI> -- A synchronous L<DBI>-based storage engine that can be used inside of Generic.  This provides the basis for the L<POE::Component::MessageQueue::Storage::DBI> module.

=item *

L<POE::Component::MessageQueue::Storage::Throttled> -- Wraps around another engine to limit the number of messages sent to be stored at once.  Use of this module is B<highly> recommended!  If the storage engine is unable to store the messages fast enough (ie. with slow disk IO) it can get really backed up and stall messages coming out of the queue, allowing execessive producers to basically monopolize the server, preventing any messages from getting distributed to subscribers.  Also, it will significantly cuts down the number of open FDs when used with L<POE::Component::MessageQueue::Storage::FileSystem>.  Internally it makes use of L<POE::Component::MessageQueue::Storage::BigMemory> to store the throttled messages.

=item *

L<POE::Component::MessageQueue::Storage::Complex> -- A configurable storage engine that keeps a front-store (something fast) and a back-store (something persistent), allowing you to specify a timeout and an action to be taken when messages in the front-store expire, by default, moving them into the back-store.  This optimization allows for the possibility of messages being handled before ever having to be persisted.  Complex is capable to correctly handle the persistent and expire-after headers.

=item *

L<POE::Component::MessageQueue::Storage::Default> -- A combination of the Complex, BigMemory, FileSystem, DBI and Throttled modules above.  It will keep messages in BigMemory and move them into FileSystem after a given number of seconds, throttling messages passed into DBI.  The DBI backend is configured to use SQLite.  It is capable to correctly handle the persistent and expire-after headers.  This is the recommended storage engine and should provide the best performance in the most common case (ie. when both providers and consumers are connected to the queue at the same time).

=back

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item storage => SCALAR

The only required parameter.  Sets the object that the message queue should use for
message storage.  This must be an object that follows the interface of
L<POE::Component::MessageQueue::Storage> but doesn't necessarily need to be a child
of that class.

=item alias => SCALAR

The session alias to use.

=item port => SCALAR

The optional port to listen on.  If none is given, we use 61613 by default.

=item address => SCALAR

The option interface address to bind to.  It defaults to INADDR_ANY or INADDR6_ANY
when using IPv4 or IPv6, respectively.

=item hostname => SCALAR

The optional name of the interface to bind to.  This will be converted to the IP and
used as if you set I<address> instead.  If you set both I<hostname> and I<address>,
I<address> will override this value.

=item domain => SCALAR

Optionally specifies the domain within which communication will take place.  Defaults
to AF_INET.

=item logger_alias => SCALAR

Optionally set the alias of the POE::Component::Logger object that you want the message
queue to log to.  If no value is given, log information is simply printed to STDERR.

=item message_class => SCALAR

Optionally set the package name to use for the Message object.  This should be a child
class of POE::Component::MessageQueue::Message or atleast follow the same interface.

This allows you to add new message headers which the MQ can recognize.

=item pump_frequency => SCALAR

Optionally set how often (in seconds) to automatically pump each queue.  If zero or
no value is given, then this timer is disabled entirely.

When disabled, each queue is only pumped when its contents change, meaning 
when a message is added or removed from the queue.  Normally, this is enough.  However,
if your storage engine holds back messages for any reason (ie. to delay their 
delivery) it will be necessary to enable this, so that the held back messages will
ultimately be delivered.

I<You must enable this for the message queue to honor the deliver-after header!>

=item observers => ARRAYREF

Optionally pass in a number of objects that will receive information about events inside
of the message queue.

Currently, only one observer is provided with the PoCo::MQ distribution:
L<POE::Component::MessageQueue::Statistics>.  Please see its documentation for more information.

=back

=head1 HIGH AVAILABILITY

From version 0.2.10, PoCo::MQ supports a features to enable high availability.

=over 4

=item B<Clustering>

You can now run multiple MQs which share the same back-store, behind a reverse-proxy load-balancer with
automatic fail-over, if one of the MQs goes down.

See the the clustering documentation for more information:

L<POE::Component::MessageQueue::Manual::Clustering>

=item B<DBI fail-over>

The DBI storage engine can be configured with a list of database servers.  If one of them is not available
or goes down, it will fail-over to the next one.

If you set up several database servers with master-to-master replication, this will allow the MQ to seemlessly
handle failure of one of the databases.

See the DBI storage engine documentation for more information:

L<POE::Component::MessageQueue::Storage::Generic::DBI>

=back

=head1 REFERENCES

=over 4

=item [1]

L<http://en.wikipedia.org/wiki/Message_Queue> -- General information about message queues

=item [2]

L<http://stomp.codehaus.org/Protocol> -- The informal "spec" for the STOMP protocol

=item [3]

L<http://www.activemq.org/> -- ActiveMQ is a popular Java-based message queue

=back

=head1 UPGRADING FROM OLDER VERSIONS

If you used any of the following storage engines with PoCo::MQ 0.2.9 or older:

=over 4

=item *

L<POE::Component::MessageQueue::Storage::DBI>

=back

The database format has changed!

B<Note:> When using L<POE::Component::MessageQueue::Storage::Default> (meaning mq.pl
--storage default) the database will be automatically updated in place, so you don't
need to worry about this.

Included in the distribution, is a schema/ directory with a few SQL scripts for 
upgrading:

=over

=item *

upgrade-0.1.7.sql -- Apply if you are upgrading from version 0.1.6 or older.

=item *

upgrade-0.1.8.sql -- Apply if your are upgrading from version 0.1.7 or after applying
the above upgrade script.  This one has a SQLite specific version: upgrade-0.1.8-sqlite.sql).

=item *

upgrade-0.2.3.sql -- Apply if you are upgrading from version 0.2.2 or older (after
applying the above upgrade scripts).

=item *

upgrade-0.2.9-mysql.sql -- Doesn't apply to SQLite users!  Apply if you are upgrading from version
0.2.8 or older (after applying the above upgrade scripts).

=item *

upgrade-0.2.10-mysql.sql -- Doesn't apply to SQLite users!  Apply if you are upgrading from version
0.2.9 or older (after applying the above upgrade scripts).

=back

=head1 CONTACT

Please check out the Google Group at:

L<http://groups.google.com/group/pocomq>

Or just send an e-mail to: pocomq@googlegroups.com

=head1 DEVELOPMENT

If you find any bugs, have feature requests, or wish to contribute, please
contact us at our Google Group mentioned above.  We'll do our best to help you
out!

Development is coordinated via Bazaar (See L<http://bazaar-vcs.org>).  The main
Bazaar branch can be found here:

L<http://code.hackyourlife.org/bzr/dsnopek/perl_mq/devel.mainline>

We prefer that contributions come in the form of a published Bazaar branch with the
changes.  This helps facilitate the back-and-forth in the review process to get
any new code merged into the main branch.

There is also an official git mirror hosted on GitHub here:

L<https://github.com/dsnopek/POE--Component--MessageQueue>

We will also accept contributions via git and GitHub pull requests!

=head1 FUTURE

The goal of this module is not to support every possible feature but rather to
be small, simple, efficient and robust.  For the most part expect incremental
changes to address those areas.

Beyond that we have a TODO list (shown below) called B<"The Long Road To
1.0">.  This is a list of things we feel we need to have inorder to call the
product complete.  That includes management and monitoring tools for sysadmins
as well as documentation for developers.

=over 4

=item *

B<Full support for STOMP>: Includes making sure we are robust to clients
participating badly in the protocol.

=item *

B<Authentication and authorization>: This should be highly pluggable, but
basically (as far as authorization goes) each user can get read/write/admin
perms for a queue which are inherited by default to sub-queues (as separated
by the dot character).

=item *

B<Monitoring/management tools>:  It should be possible for an admin to monitor the
overall state of the queue, ie: (1) how many messages for what queues are in
the front-store, throttled, back-store, etc, (2) information on connected
clients, (3) data/message thorough put, (4) daily/weekly/monthly trends, (X)
etc..  They should also be able to "peek" at any message at any point as well
as delete messages or whole queues.
The rough plan is to use special STOMP frames and "magic" queues/topics to
access special information or perform admin tasks.  Command line scripts for
simple things would be included in the main distribution and a full-featured
web-interface would be provided as a separate module.

=item *

B<Log rotation>: At minimum, documentation on how to set it up.

=item *

B<Docs on "using" the MQ>: A full tutorial from start to finish, advice on
writing good consumers/producers and solid docs on authoring custom storage
engines.

=back

=head1 APPLICATIONS USING PoCo::MQ

=over 4

=item L<http://chessvegas.com>

Chess gaming site ChessVegas.

=back

=head1 SEE ALSO

I<External modules:>

L<POE>,
L<POE::Component::Server::Stomp>,
L<POE::Component::Client::Stomp>,
L<Net::Stomp>,
L<POE::Filter::Stomp>,
L<POE::Component::Logger>,
L<DBD::SQLite>,
L<POE::Component::Generic>

I<Storage modules:>

L<POE::Component::MessageQueue::Storage>,
L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Double>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

I<Statistics modules:>

L<POE::Component::MessageQueue::Statistics>,
L<POE::Component::MessageQueue::Statistics::Publish>,
L<POE::Component::MessageQueue::Statistics::Publish::YAML>

I<ID generator modules:>

L<POE::Component::MessageQueue::IDGenerator>,
L<POE::Component::MessageQueue::IDGenerator::SimpleInt>,
L<POE::Component::MessageQueue::IDGenerator::UUID>

=head1 BUGS

We are serious about squashing bugs!  Currently, there are no known bugs, but
some probably do exist.  If you find any, please let us know at the Google group.

That said, we are using this in production in a commercial application for
thousands of large messages daily and we experience very few issues.

=head1 AUTHORS

Copyright 2007-2011 David Snopek (L<http://www.hackyourlife.org>)

Copyright 2007, 2008 Paul Driver <frodwith@gmail.com>

Copyright 2007 Daisuke Maki <daisuke@endeworks.jp>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

