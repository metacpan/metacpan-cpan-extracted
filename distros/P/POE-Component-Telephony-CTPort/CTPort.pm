package POE::Component::Telephony::CTPort;

use strict;

use vars qw($CTSERVER_RUN $VERSION $Default);

$VERSION = '0.03';

$CTSERVER_RUN = 0;

$Default = {
	DEBUG => 0,
	alias => 'ctport',
	ctserver => 'ctserver',
	paths => [],
	default_ext => '.au',
	hostname => 'localhost',
	port => 1,
	reply_to => undef,	# don't touch
	ignore_dtmf => 0,
	reconnect => 5,
	manager_port => undef,
	manager_d => -2,
};

use POE qw(Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Line Filter::Stream);
use Socket;
use Proc::ProcessTable;
use File::Basename qw(basename);
use IO::Pty; # for Wheel::Run as a pty

=pod

=head1 NAME

POE::Component::Telephony::CTPort - Non-blocking telephony programming in Perl

=head1 SYNOPSIS

	use POE qw(Compoent::Telephony::CTPort);
	
	POE::Session->create(
		inline_states => {
			_start => sub {
				my $kernel = $_[KERNEL];
				
				POE::Component::Telephony::CTPort->spawn({
					alias => 'ctport',
					port => 1,
				});
				
				$kernel->post(ctport => 'connect');
			},
			connected => sub {
				my $kernel = $_[KERNEL];
			
				print "connected to ctserver on port 1\n";
			},
			input => sub {
				my ($kernel, $in) = @_[KERNEL, ARG0];
				
				# all events are sent here, this is a good
				# spot to use Data::Dumper
				if ($in->{rly} eq 'ring') {
					$kernel->yield(ring => $in);
				}
			},
			ring => sub {
				my $kernel = $_[KERNEL];
			
				# pick up phone
				$kernel->post(ctport => 'off_hook');
				
				# play beep
				$kernel->post(ctport => play => 'beep');
				
				# record
				$kernel->post(ctport => record =>
					# to this file
					'prompt.wav',
					# for 15 seconds
					15,
					# or until they hit #
					'#',
					# or 3 seconds of silence
					3,
				);
				
				# play it back to them
				$kernel->post(ctport => play => 'prompt.wav');
				
				# play 3 beeps
				$kernel->post(ctport => play => 'beep beep beep');
				
				# hangup
				$kernel->post(ctport => 'on_hook');
				
				# shutdown
				$kernel->post(ctport => 'disconnect');
				$kernel->post(ctport => 'shutdown');
			},
		}
	);

=head1 DESCRIPTION

This module implements a non blocking perl interface to CTserver, a
server that controls voictronix card operation.

*****NOTE*****

You need a voicetronix card, the voictronix driver, and ctserver installed
to use this module!

*****NOTE*****

=head1 CONSTRUCTOR

	POE::Component::Telephony::CTPort->spawn({
		alias => 'ctport',
		port => 1 
	});

Don't start ctserver yourself, on the first spawn of CTPort, ctserver will be
launched in a fork().  To not run ctserver from this module, specify 
no_ctserver_fork => 1 as a parameter.

You can specify all or none of the parameters:

=over 4

=item *

ctserver - the path to the ctserver binary, 'ctserver' is the default (in the path)

=item *

alias - name to address the component, 'ctport' is the default

=item *

paths - search paths for the play event, as an array ref:
[ '/mnt/cdrom0', '/mnt/cdrom1' ]

=item *

default_ext - default extension for sound files (default is '.au')

=item *

reply_to - allows you to specify a different session id to send events to

=item *

hostname - default is localhost

=item *

port - a port number from 1 to 4 (1 is default)

=item *

ignore_dtmf - 1 _or_ 0 (inital setting, used for playing sounds)

=item *

no_ctserver_fork - 1 _or_ 0 (0 is default)

=back

spawn() returns a reference to the internal session, but do not keep a copy
of it.  Instead call the ID method and save that:

$heap->{ctport} = POE::Component::Telephony::CTPort->spawn()->ID;

If you spawn more than one CTPort session, change the alias! Like this:

POE::Component::Telephony::CTPort->spawn({ alias => 'ct1' });
POE::Component::Telephony::CTPort->spawn({ alias => 'ct2' });
POE::Component::Telephony::CTPort->spawn({ alias => 'ct3' });
POE::Component::Telephony::CTPort->spawn({ alias => 'ct4' });

This will spawn four sessions and you are ready to tell each one to connect to
a different ctserver port. See the 'connect' event.

=cut

sub spawn {
	my ($class, $args) = @_;

	my $debug = $args->{DEBUG} || $Default->{DEBUG};
	
	print STDERR "spawn called\n" if ($debug);

	# skip ctserver spawn if already running
	if ($CTSERVER_RUN > 0 || $args->{no_ctserver_fork}) {
		print STDERR "skipping ctserver spawn, already running\n" if ($debug);
		#return _spawn($args);
		return $poe_kernel->post(ctserver => spawn => $args);
	}
	
	print STDERR "spawning ctserver\n" if ($debug);
	
	# only allow 1 session
	$CTSERVER_RUN = 1;
	
	POE::Session->create(
		heap => {
			args => $args,
			DEBUG => $debug,
			ctserver => ($args->{ctserver} || $Default->{ctserver}),
		},
		inline_states => {
			_start => sub {
				my ($kernel, $heap, $args) = @_[KERNEL, HEAP];
				
				# reply_to workaround
				$heap->{reply_to} = $_[SENDER]->ID;
				
				$kernel->sig('INT', 'signals');
				$kernel->sig('TERM', 'signals');
				
				$kernel->alias_set('ctserver');
		
				$heap->{name} = basename($heap->{ctserver});
		
				$heap->{retries} = 0;
				
				my $p = Proc::ProcessTable->new();
				my $t = $p->table();
				foreach my $i ( 0 .. $#{$t} ) {
					next unless (exists($t->[$i]->{fname})
						&& $t->[$i]->{fname} eq $heap->{name});
					
					print STDERR "ctserver already running at pid ".$t->[$i]->{pid}."\n" if ($heap->{DEBUG});
					$kernel->yield(_kill => TERM => $t->[$i]->{pid});
					$heap->{skip_wheel} = 1; # skip wheel setup
				}
				
				# don't kill me because this is hardcoded in ctserver :)
				my $pid;
				if (-e '/var/run/ctserver.pid') {
					open(FH,'/var/run/ctserver.pid');
					$pid = (<FH>)[0];
					close(FH);
				}
				
				if (defined $pid && $pid) {
					if (kill(0,$pid)) {
						print STDERR "ctserver already running\n" if ($heap->{DEBUG});
						# still runnnig
						return $kernel->yield(_kill => TERM => $pid);
					#} else {
						# XXX normal startup
						#print STDERR "ctserver already running, but not responding\n" if ($heap->{DEBUG});
						#return $kernel->yield(_kill => 9 => $pid);
					}
				}
				
				return if ($heap->{skip_wheel});
				
				$kernel->call($_[SESSION] => 'setup_wheel');
			},
			_kill => sub {
				my ($kernel, $heap, $sig, $pid) = @_[KERNEL, HEAP, ARG0, ARG1];

				if ($heap->{"_kill_$pid"}) {

					my $p = Proc::ProcessTable->new();
					my $t = $p->table();
					foreach my $i ( 0 .. $#{$t} ) {
						next unless (exists($t->[$i]->{fname})
							&& $t->[$i]->{fname} eq $heap->{name} && $pid == $t->[$i]->{pid});
						
						print STDERR "ctserver didn't respond to $sig at pid $pid\n" if ($heap->{DEBUG});
						
						if (kill(0,$pid)) {
							# still there...
							if ($sig eq '9') {
								# give up?
								die "cannot kill ctserver at pid $pid!";
							} else {
								$sig = '9';
								kill($sig,$pid);
								# recheck in 5 seconds
								return $kernel->delay_set(_kill => 5 => '9' => $pid);
							}
						}
					}	
				
					delete $heap->{"_kill_$pid"};
				
					# ok, its gone, continue startup
					return $kernel->call($_[SESSION] => 'setup_wheel');
				} else {
					$heap->{"_kill_$pid"} = time();
					
					# DIE DIE DIE!
					kill($sig,$pid);
					
					print STDERR "sending $sig to pid $pid\n" if ($heap->{DEBUG});
					
					# recheck in 5 seconds
					$kernel->delay_set(_kill => 5 => $sig => $pid);
				}
			},
			_stop => sub {
				print STDERR "ctserver session ended\n" if $_[HEAP]->{DEBUG};
			},
			setup_wheel => sub {
				my ($kernel, $heap) = @_[KERNEL, HEAP];

				return if ($heap->{ctserver_wheel});

				if ($heap->{retries} >= 5) {
					warn 'too many restarts of the ctserver wheel, ctserver running already?';
					return;
				}

				print STDERR "setting up ctserver wheel\n" if ($heap->{DEBUG});

				$heap->{ctserver_wheel} = POE::Wheel::Run->new(
					# What we will run in the separate process
					Program			=>  $heap->{ctserver},
					Conduit			=> 'pty',
					#ProgramArgs	=> ["--log $ENV{PWD}/log"],
					# Redirect errors to our error routine
					ErrorEvent		=>  'child_error',
					# Send child died to our child routine
					CloseEvent		=>  'child_closed',
					# Send input from child
					StdoutEvent		=>  'child_STDOUT',
					
					# STDERR not usable for 
					# Send input from child STDERR
					#StderrEvent	=>  'child_STDERR',
					# Set our filters
					#StdinFilter	=>	POE::Filter::Line->new(),
					StdoutFilter	=>	POE::Filter::Line->new(),
					#StderrFilter	=>  POE::Filter::Line->new(),
				);
					
				$heap->{retries}++;
				
				# Check for errors
				if ( ! defined $heap->{ctserver_wheel} ) {
					warn 'Unable to create ctserver wheel';
					$kernel->yield('setup_wheel');
				} else {
					print STDERR "ctserver wheel is up\n" if ($heap->{DEBUG});
				}
			},
			signals => sub {
				my ($kernel, $heap, $signal) = @_[KERNEL,HEAP,ARG0];
			
				return undef unless ($signal eq 'INT' || $signal eq 'TERM');
				
				$heap->{int}++;
				if ($heap->{int} > 1) {
					print "ok, ok, bye!\n";
					exit;
				}
				print "INT signal received, please wait, closing ctserver...\n";
				$kernel->sig_handled();
				$kernel->alarm_remove_all();
				$kernel->call($_[SESSION] => 'shutdown');
				
				return undef;
			},
			shutdown => sub {
				my ($kernel, $heap) = @_[KERNEL, HEAP];
				
				return if ($heap->{shutdown});
				
				$heap->{shutdown} = 1;	

				$kernel->alarm_remove_all();
			
				if (ref($heap->{children}) eq 'HASH') {
					foreach my $c (keys %{$heap->{children}}) {
						print STDERR "telling session $c to shutdown\n" if ($heap->{DEBUG});
						$kernel->call($c => '_shutdown');
					}
				}
				
			},
			drop_wheel => sub {
				my ($kernel, $heap) = @_[KERNEL, HEAP];
			
				if ($heap->{ctserver_wheel}) {
					$heap->{ctserver_wheel}->kill('TERM');
				}
				delete $heap->{ctserver_wheel};
				$kernel->call(ct_man_port => '_shutdown');	
				$kernel->alias_remove();
			},
			'child_error' => sub {
				my ( $operation, $errnum, $errstr ) = @_[ ARG0 .. ARG2 ];
				print STDERR "ctserver got an $operation error $errnum: $errstr\n" if ($_[HEAP]->{DEBUG});
			},
			'child_closed' => sub {
				my ($kernel, $heap) = @_[KERNEL,HEAP];
		
				print STDERR "ctserver wheel closed\n" if ($heap->{DEBUG});
		
				return if ($heap->{shutdown});

				# Emit debugging information
				warn 'ctserver\'s Wheel died! Restarting it...';
	
				# Create the wheel again
				delete $heap->{ctserver_wheel};
				$kernel->call($_[SESSION] => 'setup_wheel');
			},
			'child_STDOUT' => sub {
				my ($kernel, $heap, $input) = @_[KERNEL,HEAP,ARG0];
				
				print STDERR "ctserver Got STDOUT ( $input )\n" if ($heap->{DEBUG});
				
				# when the server is ready to accept connections, then spawn the client to connect
				if ($CTSERVER_RUN == 1 && $input =~ m/Started!/) {
					$CTSERVER_RUN++;
					# internal manager
					$kernel->yield(spawn => {
						DEBUG => $heap->{DEBUG},
						alias => 'ct_man_port',
						reconnect => 1,
						manager_port => 1198,
						manager_d => 1
					});
					# the requested port connect
					$kernel->yield(spawn => $heap->{args});
				} elsif ($input =~ m/Address already in use Giving up/) {
					# TODO search for pid first...
					system("killall -9 ctserver");
				}
			},
			'child_STDERR' => sub {
				my $input = $_[ARG0];
	
				# Skip empty lines 
				if ( $input eq '' ) { return }
	
				print STDERR "ctserver Got STDERR ( $input )\n" if ($_[HEAP]->{DEBUG});
			},
			spawn => sub {
				# reply_to workaround
				if (!$_[ARG0]->{reply_to}) {
					$_[ARG0]->{reply_to} = $_[HEAP]->{reply_to};
				}
				_spawn($_[ARG0]);
			},
			_child => sub {
				print STDERR "ctserver child $_[ARG0] session_id:".$_[ARG1]->ID."\n" if ($_[HEAP]->{DEBUG});
				if ($_[ARG0] eq 'create') {
					#my $s = $_[KERNEL]->alias_resolve('ct_man_port');
					#if (ref($s) && $s->ID != $_[ARG1]->ID) {
						$_[HEAP]->{children}{$_[ARG1]->ID} = 1;
					#}
				} elsif ($_[ARG0] eq 'lose') {
					delete $_[HEAP]->{children}{$_[ARG1]->ID};
				}
			},
		},
	);
}

sub _spawn {
	my $args = shift;
	POE::Session->create(
		args => [ $args ],
		package_states => [
			'POE::Component::Telephony::CTPort' => [qw(
				_start
				_stop
				_sock_up
				_sock_failed
				_sock_down
				_shutdown

				put
				connect	
				disconnect
				reconnect
		
				input
	
				off_hook
				on_hook
				wait_for_ring
				wait_for_dial_tone
				play_tone
				stop_tone
				play_stop
				play
				_play
				record
				record_stop
				sleep
				clear
				clear_events
				collect
				dial
				wait_for_event
				start_timer
				stop_timer
				join
				bridge
				unbridge
				join_conference
				leave_conference
				start_ring
				stop_ring
				ring_once	
				grunt_on
				grunt_off
				default_ext
				ignore_dtmf
				set_script_name
				send_cid
				listen_for_cid_jp
				listen_for_cid
				read_cid
			
				port_reset
				port_status
				roll_log
				ser_version
				shutdown
			)],
		],
	);
}


sub _start {
	my ($kernel, $heap, $sender, $args) = @_[KERNEL, HEAP, SENDER, ARG0];
	
	$heap->{$_} = $args->{$_} || $Default->{$_} foreach
		qw(DEBUG alias paths default_ext reply_to ignore_dtmf hostname port reconnect manager_port manager_d);

	$heap->{DEBUG} && do {
		print STDERR "params:\n";
		foreach my $h (keys %$heap) {
			print STDERR "$h = $heap->{$h}\n";
		}
	};
	
	$kernel->alias_set($heap->{alias});
#	$kernel->refcount_increment($sender->ID, __PACKAGE__);
	$heap->{reply} = $heap->{reply_to} || $sender->ID;
	$kernel->yield('connect');
}

sub _stop {
	print STDERR "ctport session ended\n" if $_[HEAP]->{DEBUG};
}

sub _sock_up {
	my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
	
	print STDERR "sock up for session ".$_[SESSION]->ID."\n" if ($heap->{DEBUG});
	
	$heap->{sock} = POE::Wheel::ReadWrite->new(
		Handle => $socket,
		Driver => POE::Driver::SysRW->new(),
		Filter => POE::Filter::Line->new(Literal => "\n"),
		ErrorEvent => '_sock_down',
		InputEvent => 'input',
	);
	
	$kernel->post($heap->{reply} => 'connected' => splice(@_,ARG0));
}

sub _sock_failed {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	print STDERR "sock failed for session ".$_[SESSION]->ID."\n" if ($heap->{DEBUG});
	
	delete $heap->{sock};
	return if ($heap->{shutdown});
	
	$kernel->post($heap->{reply} => 'socket_error' => splice(@_,ARG0));
	
	if (defined $heap->{reconnect}) {
		$kernel->delay_set('reconnect' => $heap->{reconnect});
	}
}

# sigh, repeat code..
sub _sock_down {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	print STDERR "sock down for session ".$_[SESSION]->ID."\n" if ($heap->{DEBUG});
	
	delete $heap->{sock};
	return if ($heap->{shutdown});
	
	$kernel->post($heap->{reply} => 'disconnected' => splice(@_,ARG0));

	if (defined $heap->{reconnect}) {
		$kernel->delay_set('reconnect' => $heap->{reconnect});
	}
}

sub _shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$heap->{shutdown} = 1;
	
	print STDERR "_shutdown called on session ".$_[SESSION]->ID."\n" if ($heap->{DEBUG});

	$kernel->call(ct_man_port => send_event => $heap->{port} => 'SHUTTING_DOWN');
	$kernel->call($_[SESSION] => 'on_hook');
	#$kernel->call($_[SESSION] => 'shutdown');
}

sub reconnect {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	print STDERR "reconnect called\n" if ($heap->{DEBUG});
	
	return unless (defined $heap->{hostname} && defined $heap->{port});

	print STDERR "reconnecting to $heap->{hostname} $heap->{port}\n" if ($heap->{DEBUG});

	delete $heap->{sock};
	
	$kernel->yield('connect' => {
		hostname => $heap->{hostname},
		port => $heap->{port},
	});
}

sub put {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	return unless ($heap->{sock});
	if (ref($heap->{sock}) eq 'POE::Wheel::SocketFactory') {
		# not connected yet!
		print STDERR "not connected yet, queueing command until connect\n" if ($heap->{DEBUG});
		$_[KERNEL]->delay_set(put => 1 => splice(@_,ARG0));
		return;
	}
	my $line = $_[ARG0];
	if ($line !~ m/ $/) {
		$line .= " ";
	}
	$heap->{sock}->put($line);
	print STDERR "put: '$line'\n" if ($heap->{DEBUG});
}

=pod

=head1 NOTES

Any 'blocking' mentioned in this document is only related to the port does not
send or receive commands, POE will NOT block for any of these events.

It takes alot of experimenting with this module and ctserver to get a working
routine down.  My advice is to start off with 1 command, and analize the results
and setup your script to watch for those results before sending the next command.
Firing off the commands without knowing what is happening doesn't work well. :)

The alias 'ctserver' is used internally for spawning and handling ctserver.  Do
not use this alias in your scripts.  Its ok to fire its shutdown event to start
a safe shutdown.

This will module will probably not work on win32. (windows)

=head1 RECEIVING EVENTS

Your session will receive an event 'ct_input'
ARG0 will be a parsed version
of ARG1.  ARG1 is the raw text from the server.

Heres a dump of ARG0, a response from a off_hook event:

	{
		'src' => '3',
		'rly' => 'ctanswer',
		'args' => [
			'OK'
		],
		'dst' => '3',
		'argc' => '1'
	}

This is ARG1 from the above dump.

	rly=ctanswer src=3 dst=3 arg1=OK argc=1

You need to check the first arg of args to see if it is an
event like the one listed below.

=head2 dtmf

=head2 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, *, #

=head2 hangup

=head2 loopdrop

=head2 ring

=head2 pickup

=head2 timer

=head2 cid

=head2 flash

=head2 toneend

=cut

sub input {
	my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

	$input =~ s/\0//g;
	
	my %in;
	foreach (split(/ /,$input)) {
		my ($k,$v) = split(/=/);
		if ($k =~ m/^arg(\d+)/) {
			$in{args}->[($1-1)] = $v;
		} else {
			$in{$k} = $v;
		}
	}

	$kernel->post($heap->{reply} => 'ct_input' => \%in => $input);
}

=pod

=head1 SENDING EVENTS

=head2 connect

Connects to the ctserver and port specified in the spawn constructor.
You can also pass a hash ref of hostname and port(1-4) to override.

=cut

sub connect {
	my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG0];
	$heap->{$_} = $args->{$_} || $heap->{$_} foreach qw(hostname port);

#	return if $heap->{sock};
	
	my $conport = $heap->{port} + 1199;
	
	$heap->{handle} = $heap->{port} - 1;
	$heap->{d_handle} = $heap->{port} - 1;
	
	if ($heap->{manager_port} && $heap->{manager_port} > 0) {
		$conport = $heap->{manager_port};
		$heap->{port} = -2;
		$heap->{handle} = -2;
		$heap->{d_handle} = $heap->{manager_d};
	}
	
	$heap->{sock} = POE::Wheel::SocketFactory->new(
		SocketDomain => AF_INET,
		SocketType => SOCK_STREAM,
		SocketProtocol => 'tcp',
		RemoteAddress => $heap->{hostname},
		RemotePort => $conport,
		SuccessEvent => '_sock_up',
		FailureEvent => '_sock_failed',
	);
}

=head2 disconnect

Disconnects from the ctserver.

Note: Disconnecting doesn't stop a currently running
record, play, ect.

=cut

sub disconnect {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	delete $heap->{sock};
}

#	"ctanswer"
#		SUMMARY:	takes the port off hook [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 off_hook

Takes port off hook, like picking up the phone.

=cut

sub off_hook {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctanswer src=%d dst=%d argc=0',$heap->{handle},$heap->{d_handle}));
}

#	"cthangup"
#		SUMMARY:	places the port on hook [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 on_hook

Puts the port on hook, like hanging up the phone.

=cut

sub on_hook {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=cthangup src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctwaitforring"
#		SUMMARY: 	Waits for a ring event and returns the caller ID if
#				available [blocking]
#		ARGS: 		arg1=<number of rings to wait for (def 2)>
#		RETURN ARGS: 	arg1=[OK|ERROR|EVENT]
#				arg2=<Caller ID>
#				arg3=<event>

=pod

=head2 wait_for_ring

Blocks until port detects a ring, then returns.  The caller
ID (if present) will be returned.

=cut

sub wait_for_ring {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $rings = $_[ARG0] || 2;
	my $ird = $_[ARG1] || 0;

	$kernel->yield(put =>
		sprintf('cmd=ctwaitforring src=%d dst=%d arg1=%d arg2=%s argc=2',
		$heap->{handle},$heap->{d_handle},$rings,$ird));
}

#	"ctwaitfordial"
#		SUMMARY:	Waits for a dialtone for a max of 10 seconds [blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 wait_for_dial_tone

Blocks until dial tone detected on port, then returns.

=cut

sub wait_for_dial_tone {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctwaitfordial src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctplaytoneasync"
#		SUMMARY:	plays a tone asyncronously [non-blocking]
#		ARGS: 		arg1=<tone type>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 play_tone => $type

Plays a tone.  $type can be busy, dialx, dial, or ringback.
A warning is produced if you supply an invalid tone.

=cut

sub play_tone {
	my ($kernel, $heap, $type) = @_[KERNEL, HEAP, ARG0];
	$type = lc($type);
	
	my $found = 0;
	foreach my $t (qw(busy dialx dial ringback)) {
		$found = 1 if ($type eq $t);
	}
	unless ($found) {
		warn "play_tone: ctserver does not support tone $type";
		return;
	}

	$kernel->yield(put => sprintf('cmd=ctplaytoneasync src=%d dst=%d arg1=%s argc=1',
		$heap->{handle},$heap->{d_handle},$type));
}

#	"ctstoptone"
#		SUMMARY:	stops an asynronous tone playing [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 stop_tone

Stops a playing tone

=cut

sub stop_tone {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctstoptone src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctplay_stop"
#		SUMMARY:	Stops an asyncronous play [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 play_stop

Stops current playback.

=cut

sub play_stop {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctplay_stop src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 play => $file _or_ play => \@files _or_ play => [ $file1, $file2, $file3 ]

Plays audio files, playing stops immediately if a DTMF key is 
pressed.  Any digits pressed while playing will be added to the digit buffer.

It accepts a space seperated list of files:
$kernel->post(ctport => play => "1 2 3");

or an array of files:
$kernel->post(ctport => play => ['hello', 'world']);

Filename extensions:

=over 4

=item *

The default is .au, can be redefined by posting/calling the default_ext
event with the file extension as the first parameter.  For example:
$kernel->post(ctport => default_ext => '.wav');

=item *

You can override the default by providing the extension:
$kernel->post(ctport => play => "hello.wav");

=back

Searches for file in:

=over 4

=item *

The paths defined by set_path event or as an option to the spawn
constructor: { path => '/var/audio/files/' }

=item *

The current directory

=item *

The "prompts" sub dir (relative to the current directory)

=item *

full path supplied by caller

=item *

/var/ctserver/UsMEng

=back

You can play multiple files

$kernel->post(ctport => play => "Hello World");
(assumes you have Hello.au and World.au files available)
(depending on what the default extension is set to)

You can "speak" a limited vocabulary: 
$kernel->post(ctport => play => "1 2 3"); 

See the /var/ctserver/UsMEng directory for the list of included files that
defines the vocabulary.

=cut


# see below for $async flag 
sub play {
	my ($kernel, $files, $async) = @_[KERNEL, ARG0, ARG1];

	return unless ($files);
	
	$files = join(' ',@{$files}) if (ref($files) eq 'ARRAY');

	foreach my $f (split(/ /,$files)) {
		$kernel->yield(_play => $f => $async);
	}
}

#	"ctplay"
#		SUMMARY:	Plays a file and deals with events [blocking]
#		ARGS: 		arg1=<file to play>
#		RETURN ARGS:	arg1=[OK|ERROR|EVENT]
#				arg2=<digits>
#				arg3=<event>
#
#	"ctplay_async"
#		SUMMARY:	Plays a file asyncronously [non-blocking]
#		ARGS: 		arg1=<file to play>
#		RETURN ARGS:	arg1=[OK|ERROR]

sub _play {
	my ($kernel, $heap, $file, $async) = @_[KERNEL, HEAP, ARG0, ARG1];

	# TODO verify this works
	unless ($file =~ m/\./) {
		$file .= $heap->{default_ext};
	}
	my @path;

	if ($file =~ /^\//) {
		push(@path,$file);
	}

	# user supplied paths
	if ($heap->{paths}) {
		my $pt = $heap->{paths};
		for my $i ( 0 .. $#{$pt} ) {
			# make sure there's a slash on the end
			$pt->[$i] .= "/" unless ($pt->[$i] =~ m/\/$/);
			$pt->[$i] .= $file;
		}
		push(@path,@{$pt});
	}
	# undocumented feature...search only supplied path
	# TODO doc this
	unless ($heap->{paths_only}) {
		# current directory (at program start)
		push(@path,"$ENV{PWD}/$file");
		# prompts subdir
		push(@path,"$ENV{PWD}/prompts/$file");
		# default ctserver english (use 'paths' above to avoid english)
		push(@path,"/var/ctserver/USEngM/$file");
	}
	
	foreach my $p (@path) {
		if (-e "$p") {
			my ($extra,$num) = ('',1);
			# check for the ignore dtmf option
			if ($heap->{ignore_dtmf}) {
				$extra = ' arg2=ignore_dtmf';
				$num = 2;
			}
			if (defined($async)) {
				$kernel->yield(put => sprintf('cmd=ctplayasync src=%d dst=%d arg1=%s%s argc=%d',
					$heap->{handle},$heap->{d_handle},$p,$extra,$num));
			} else {
				$kernel->yield(put => sprintf('cmd=ctplay src=%d dst=%d arg1=%s%s argc=%d',
					$heap->{handle},$heap->{d_handle},$p,$extra,$num));
			}
			return;
		}
	}
	
	warn "play: File(s) not found: ".join(';',@path);
}

#	"ctrecord"
#		SUMMARY:	Records audio to a file [blocking]
#		ARGS: 		arg1=<file to record to>
#				arg2=<time out>
#				arg3=<terminating digits>
#				arg4=<silence timeout>
#		RETURN ARGS:	arg1=[OK|ERROR|EVENT]
#				arg2=<digits>
#				arg3=<event>

=pod

=head2 record => $file_name => $seconds => $digits

Records $file_name for $seconds seconds or until any of the digits in $digits
are pressed.  The path of $file_name is considered absolute if there is a
leading /, otherwise it is relative to the current directory.

=cut

sub record {
	my ($kernel, $heap, $file) = @_[KERNEL, HEAP, ARG0];
	
	# TODO does duration 0 mean until a digit is pressed?
	my $timeout = @_[ARG1] || 0;
	my $digits = @_[ARG2] || '';
	my $silence = @_[ARG3] || 0;

	if ($file !~ m/^\//) {
		$file = "$ENV{PWD}/$file";
	}

	$kernel->yield(put => sprintf('cmd=ctrecord src=%d dst=%d arg1=%s arg2=%d arg3=%s arg4=%d argc=4',
		$heap->{handle},$heap->{d_handle},$file,$timeout,$digits,$silence));
}

=pod

=head2 record_stop

Stops recording on the current port.

=cut

sub record_stop {
	my ($kernel, $heap, $file) = @_[KERNEL, HEAP, ARG0];
	
	# since ctserver doesn't have a direct way to call vpb_record_terminate, we use this work around
	# a user message sent to the port while recording causes it to stop

	$kernel->post(ct_man_port => send_event => $heap->{port} => 'RECORD_STOP');
}

#	"ctsleep"
#		SUMMARY:	Sleep for N seconds [blocking]
#		ARGS: 		arg1=<seconds>
#		RETURN ARGS:	arg1=[OK|ERROR|EVENT]
#				arg2=<digits>
#				arg3=<event>

=pod

=head2 sleep => $seconds

Blocks for $seconds, unless a DTMF key is pressed in which
case it returns immediately.  If $ctport->event() is already defined it 
returns immediately without sleeping.

=cut

sub sleep {
	my ($kernel, $heap, $secs) = @_[KERNEL, HEAP, ARG0];

	unless ($secs =~ m/^\d+$/) {
		warn "sleep: Seconds must be a number, ie '2' not 'two' :)";
		return;
	}
	
	$kernel->yield(put => sprintf('cmd=ctsleep src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$secs));
}

#	"ctclear"
#		SUMMARY:	Clears the digit buffer [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 clear

Clears the DTMF digit buffer. (It may clear events too!)

=cut

sub clear {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$kernel->yield(put => sprintf('cmd=ctclear src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
	delete $heap->{buffer};
}

#	"ctclearevents"
#		SUMMARY:	Clears the event queue [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 clear_events

Clears the event queue.

=cut

sub clear_events {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$kernel->yield(put => sprintf('cmd=ctclearevents src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctcollect"
#		SUMMARY:	Collects digits [blocking]
#		ARGS: 		arg1=<number of digits to collect>
#				arg2=<time out>
#				arg3=<inter digit delay>
#		RETURN ARGS:	arg1=[OK|ERROR|EVENT]
#				arg2=<digits>
#				arg3=<event>

=pod

=head2 collect => $max_digits => $max_seconds

Returns up to $max_digits by waiting up to $max_seconds.  Will return as soon
as either $max_digits have been collected or $max_seconds have elapsed.  On
return, the event() method will return undefined.  

DTMF digits pressed at any time are collected in the digit buffer.  The digit
buffer is cleared by the clear method.  Thus it is possible for this function
to return immediately if there are already $max_digits in the digit buffer.

=cut

# XXX hmm, how do we do this in an event model?
sub collect {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $maxdigits = $_[ARG0] || 0;
	my $maxseconds  = $_[ARG1] || 0;
	my $maxinter = $_[ARG2] || 0;
	
	$kernel->yield(put => sprintf('cmd=ctcollect src=%d dst=%d arg1=%d arg2=%d arg3=%d argc=3',
		$heap->{handle},$heap->{d_handle},$maxdigits,$maxseconds,$maxinter));
}

#	"ctdial"
#		SUMMARY:	Dials a string of digits [blocking]
#		ARGS: 		arg1=<digits to dial>
#		RETURN ARGS:	arg1=[OK|ERROR|EVENT]
#				arg2=<event>

=pod

=head2 dial => $number

Dials a DTMF string.  Valid characters are 1234567890#*,&

=over 4

=item *

, gives a 1 second pause, e.g. $ctport->dial(",,1234) will wait 2 seconds, 
then dial extension 1234.

=item *

& generates a hook flash (used for transfers on many PBXs):

$kernel->post(ctport => dial => '&,1234'); will send a flash, wait one second,
then dial 1234. 

=back

=cut

sub dial {
	my ($kernel, $heap, $dial) = @_[KERNEL, HEAP, ARG0];

	#$dial =~ s/\D//g;
	
	$kernel->yield(put => sprintf('cmd=ctdial src=%d dst=%d arg1=%s argc=1',
		$heap->{handle},$heap->{d_handle},$dial));
}

#	"ctwaitforevent"
#		SUMMARY:	waits for an event [blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]
#				arg2=<event>

=pod

=head2 wait_for_event

Blocks, waits for an event to happen.
(probably not useful in POE)

=cut

sub wait_for_event {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$kernel->yield(put => sprintf('cmd=ctwaitforevent src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctsendevent"
#		SUMMARY:	sends an event/message to another port [non-blocking]
#		ARGS: 		arg1=<message>
#				...
#				arg9=<message>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 send_event => $port => $event

Sends an event or message to another port.

=cut

sub send_event {
	my ($kernel, $heap, $port, $msg) = @_[KERNEL, HEAP, ARG0, ARG1];
	
	$kernel->yield(put => sprintf('cmd=ctsendevent src=%d dst=%d arg1=%s argc=1',
		$heap->{handle},$port,$msg));
}

#	"ctstarttimerasync"
#		SUMMARY:	starts an asyncronous timer [non-blocking]
#		ARGS: 		arg1=<time in seconds>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 start_timer => $seconds

Starts a timer that will send an event in $seconds seconds.

=cut

sub start_timer {
	my ($kernel, $heap, $secs) = @_[KERNEL, HEAP, ARG0];
	
	$kernel->yield(put => sprintf('cmd=ctstarttimerasync src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$secs));
}

#	"ctstoptimer"
#		SUMMARY:	stops an asyncronous timer [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 stop_timer

Stops the current timer.

=cut

sub stop_timer {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	$kernel->yield(put => sprintf('cmd=ctstoptimer src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctjoin"
#		SUMMARY:	bridges two ports [non-blocking]
#		ARGS: 		arg1=<first port>
#				arg2=<second port>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 join => $port1 => $port2

Bridges $port1 and $port2.

=cut

sub join {
	my ($kernel, $heap, $port1, $port2) = @_[KERNEL, HEAP, ARG0, ARG1];

	$kernel->yield(put => sprintf('cmd=ctjoin src=%d dst=%d arg1=%d arg2=%d argc=2',
		$heap->{handle},$heap->{d_handle},$port1,$port2));
}

#	"ctbridge"
#		SUMMARY:	hardware bridges this port with one supplied [non-blocking]
#		ARGS: 		arg1=<other port>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 bridge => $port

Hardware bridges the connected port to $port.

=cut

sub bridge {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=ctbridge src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$port));
}

#	"ctunbridge"
#		SUMMARY:	Unbridges this port with one supplied [non-blocking]
#		ARGS: 		arg1=<other port>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 unbridge => $port

Unbridges the connected port and $port.

=cut

sub unbridge {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=ctunbridge src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$port));
}

#	"ctjoinconference"
#		SUMMARY:	Joins a port to a conference.
#		ARGS:		arg1=<other port>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 join_conference => $port


Joins a port to a conference.

=cut

sub join_conference {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=ctjoinconference src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$port));
}

#	"ctleaveconference"
#		SUMMARY:	Removes a port from a conference.
#		ARGS:		arg1=<other port>
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 leave_conference => $port

Removes $port from a conference.

=cut

sub leave_conference {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=ctleaveconference src=%d dst=%d arg1=%d argc=1',
		$heap->{handle},$heap->{d_handle},$port));
}

#	"ctstartringasync"
#		SUMMARY:	Starts this port ringing [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 start_ring

Starts ringing the connected port.

=cut

sub start_ring {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctstartringasync src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctstopring"
#		SUMMARY:	Stops this port from ringing [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 stop_ring

Stops the connected port from ringing.

=cut

sub stop_ring {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctstopring src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

#	"ctstartringonceasync"
#		SUMMARY:	Ring this port once [non-blocking]
#		ARGS: 		none
#		RETURN ARGS:	arg1=[OK|ERROR]

=pod

=head2 ring_once

Rings the connected port once.

=cut

sub ring_once {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctstartringonceasync src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 grunt_on

Turns grunt (non-silence) detection on.

=cut

sub grunt_on {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctgrunton src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 grunt_off

Turns grunt (non-silence) detection on.

=cut

sub grunt_off {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctgruntoff src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 default_ext => '.wav'

Changes default extension for playing files.

=cut

sub default_ext {
	my ($kernel, $heap, $arg) = @_[KERNEL, HEAP, ARG0];

	unless (defined($arg)) {
		warn 'You must specify an extension to default_ext';
		return;
	}

	if ($arg !~ m/^\./) {
		$arg = ".$arg";
	}
	
	$heap->{default_ext} = $arg;
}

=pod

=head2 ignore_dtmf => 1 _or_ 0

Turns on/off the ability for the caller to stop playback with dtmf.

=cut

sub ignore_dtmf {
	my ($kernel, $heap, $arg) = @_[KERNEL, HEAP, ARG0];

	unless (defined($arg)) {
		warn 'You must specify \'on\' / \'off\' or 1 / 0 to ignore_dtmf';
		return;
	}
	
	$heap->{ignore_dtmf} = ($arg =~ m/on/i || $arg =~ m/^1$/) ? 1 : 0;
}

# WTF is this useful for?
=pod

=head2 set_script_name => $name

This allows you to set a name on this port.  Shown in a port_status event. 

=cut


sub set_script_name {
	my ($kernel, $heap, $name) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=ctsetscript src=%d dst=%d arg1=%s argc=1',
		$heap->{handle},$heap->{d_handle},$name));
}

=pod

=head2 send_cid => $number => $name

Sends caller id

=cut

sub send_cid {
	my ($kernel, $heap, $number, $name) = @_[KERNEL, HEAP, ARG0, ARG1];

	$number =~ tr/\D//;

	$kernel->yield(put => sprintf('cmd=ctsetscript src=%d dst=%d arg1=%d arg2=%s argc=2',
		$heap->{handle},$heap->{d_handle},$number,$name));
}

# XXX you shouldn't have to do the timing yourself
# what is the dif between the jpcid and just cid cmds?

=pod

=head2 listen_for_cid_jp

Call after teh first ring on trunk port to start listening for
caller ID.  I'm not sure what JP is, but its not the same as the
command below.

=cut

sub listen_for_cid_jp {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctlistenforjpcid src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 listen_for_cid

Call after teh first ring on trunk port to start listening for
caller ID. After the second ring, you should call read_cid to get
the caller id if it's available.

=cut

sub listen_for_cid {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctlistenforcid src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

=pod

=head2 read_cid

Call this after the second ring on a trunk port to receive a caller id
event.

=cut

sub read_cid {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=ctreadcid src=%d dst=%d argc=0',
		$heap->{handle},$heap->{d_handle}));
}

# XXX management commands

#	"portreset"
#		SUMMARY:	Reset a port
#		DST:		<port>
#		ARGS:		none
#		RETURN ARGS:	none

sub port_reset {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	$kernel->yield(put => sprintf('cmd=portstatus src=%d dst=%d argc=0',
		$heap->{handle},$port));
}

#	"portstatus"
#		SUMMARY:        Querys server for status of each port
#		DST:            -2 [mandatory]
#		ARGS:           none
#		RETURN ARGS:    none

# XXX I was reading server.cpp... you CAN send portstatus to a port to
# get the status for 1 port or send portstatus to the manager and get
# the status for all ports

=pod

=head2 port_status => $port

Requests port status on a port, if $port is undef or -2, all ports are
polled for status

=cut

sub port_status {
	my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

	# -2 means all
	$port = (defined($port)) ? $port : -2;
	
	$kernel->yield(put => sprintf('cmd=portstatus src=%d dst=%d argc=0',
		$heap->{handle},$port));
}

#	"rolllog"
#		SUMMARY:        Close current  ctserver log and open new log with current date
#		DST:            -2 [mandatory]
#		ARGS:           none
#		RETURN ARGS:    none

=pod

=head2 roll_log

Tells ctserver to close the current log, and open a new one with the current
date

=cut

sub roll_log {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=rolllog src=%d dst=-2 argc=0',
		$heap->{handle}));
}

#	"serversion"
#		SUMMARY:	Querys server for CVS identification strings
#		DST:		-2 [mandatory]
#		ARGS:		none
#		RETURN ARGS:	none

=pod

=head2 ser_version

Requests the server version from ctserver

=cut

sub ser_version {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=serversion src=%d dst=-2 argc=0',
		$heap->{handle}));
}

#	"shutdown"
#		SUMMARY:	Shutdown server.
#		DST:		-2 [mandatory]
#		ARGS:		none
#		RETURN ARGS:	none

=pod

=head2 shutdown

Shutsdown the server and the connection.

=cut

sub shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];

	$kernel->yield(put => sprintf('cmd=shutdown src=%d dst=-2 argc=0',
		$heap->{handle}));
	$kernel->alarm_remove_all();
	$kernel->alias_remove();
}

1;
__END__

=head1 TODO

The docs are lacking somewhat, so use the source if you get confused.

Automation of the caller_id events into a more simple structure.

=head1 BUGS

Please report any bugs to the author.  Patches are welcome.

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>

If you use this module, please send comments, complaints or suggetions
to the author.

=head1 SEE ALSO

L<POE>

L<Telephony::CTPort> (v0.3 doesn't work with the new ctserver)

ctserver, http://www.voicetronix.com.au/open-source.htm#ctserver

teknikill, http://teknikill.net/

