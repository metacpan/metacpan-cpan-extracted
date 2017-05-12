#!/usr/bin/perl
# A POE::Component::Server::FTP daemon that talks to its console counterpart

use strict;
#use warnings FATAL => "all";

use lib qw(/projects/lib);
use Filesys::Virtual;
use POE qw( Filter::Reference Component::Server::FTP Component::Server::TCP Component::TSTP Wheel::Run);
use YAML qw( Dump );


POE::Component::TSTP->create(
	PreSuspend => sub { print "I' being suspended! Quick, put me in the background!\n"; },
	PostSuspend => sub { print "Ahhhh, that's better!\n"; }
);

# ftp connection tracker
my %conn;
# console connection tracker
my %clients;
my @log;

my %ftpd_settings = (
#	Alias           => 'ftpd',						# ftpd is default
	ListenPort      => 21,							# port to listen on
	Domain			=> 'blah.net',					# domain shown on connection
	Version			=> 'ftpd '.$POE::Component::Server::FTP::VERSION,	# shown on connection, you can mimic...
	AnonymousLogin	=> 'deny',						# deny, allow
	FilesystemClass => 'Filesys::Virtual::Plain',	# Currently the only one available
	FilesystemArgs  => {
		'root_path' => '/',							# This is actual root for all paths
		'cwd'       => '/',							# Initial current working dir
		'home_path' => '/home',						# Home directory for '~'
	},
	# use 0 to disable these Limits
#	DownloadLimit	=> (50 * 1024),					# 50 kb/s per ip/connection (use LimitScheme to configure)
#	UploadLimit		=> (100 * 1024),				# 100 kb/s per ip/connection (use LimitScheme to configure)
	DownloadLimit	=> 0,							# 50 kb/s per ip/connection (use LimitScheme to configure)
	UploadLimit		=> 0,							# 100 kb/s per ip/connection (use LimitScheme to configure)
	LimitScheme		=> 'ip',						# ip or per (connection)
	LogLevel		=> 4,							# 4=debug, 3=less info, 2=quiet, 1=really quiet
	TimeOut			=> 120,							# Connection Timeout
	# NOT FINISHED, don't worry about it, its going to be a postprocesser instead
	VirusCheckerName => 'F-Prot',
	VirusCheckerCmd	=> '/usr/local/f-prot/f-prot',
	VirusCheckerParams => [qw( -list )],						# array ref of params
	VirusCheckerRegex => '//',
	VirusCheckerExitCodes => {
		0 => {
			op		=> 0, # do nothing
			text	=> 'Normal exit.  Nothing found, nothing done',
		},
		1 => {
			op		=> 1, # log it
			text	=> 'Unrecoverable error (for example, missing SIGN.DEF)',
		},
		2 => {
			op		=> 1, # log it
			text	=> 'Selftest failed (program has been modified)',
		},
		3 => {
			op		=> 2, # ???
			text	=> 'At least one virus-infected object was found',
		},
		4 => {
			op		=> 1, # log it
			text	=> 'Reserved, not currently in use',
		},
		5 => {
			op		=> 1, # log it
			text	=> 'Abnormal termination (scanning did not finish)',
		},
		6 => {
			op		=> 2, # ???
			text	=> 'At least one virus was removed',
		},
		7 => {
			op		=> 1, # log it
			text	=> 'Error, out of memory (should never happen, but well...)',
		},
		8 => {
			op		=> 2, # log it
			text	=> 'Something suspicious was found, but no recognized virus',
		},
	},
);

POE::Component::Server::FTP->spawn(%ftpd_settings);

POE::Component::Server::TCP->new(
	Alias => "cs",
	Address      => "127.0.0.1",
	Port         => 2021,
	ClientFilter => "POE::Filter::Reference", # Handles perl data structures
	ClientConnected => sub {
		my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
		print "Client connected from $heap->{remote_ip}\n";
		
		$clients{$session->ID} = { remote_ip => $heap->{remote_ip} };
		
		$kernel->call($session->ID => send => { log => \@log });
		$kernel->call($session->ID => send => { conn => \%conn });
	},
	ClientInput => sub {
		my ( $kernel, $heap, $session, $data ) = @_[ KERNEL, HEAP, SESSION, ARG0 ];
		my %response;
		if ( ref($data) eq 'HASH' ) {
			#require Data::Dumper;
			#print Data::Dumper->Dump([$data],['data']);
			if (exists($data->{event}) && $data->{event} eq 'chat_msg') {
				foreach my $c (keys %clients) {
					next if ($c == $session->ID);
					$kernel->call($c => send => $data);
				}
			}	
        } else {
			$response{status} = "Error: Bad request type: " . ref($data);
        }

		if (keys %response) {
			$kernel->call($session->ID => send => \%response);
		}
	},
	ClientDisconnected => sub {
		my ($kernel, $session) = $_[KERNEL, SESSION];
		print "Client Disconnected\n";
		
		if (ref($session)) {
			delete $clients{$session->ID};
		}
	},
	InlineStates => {
		send => sub {
			my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

			if ($heap->{client}) {
				#if (exists($data->{event}) && $data->{event} ne 'ftpd_write_log') {
				#	print Dump($data);
				#}
				$heap->{client}->put($data);
			}
			
		},
	},
);

POE::Session->create(
	inline_states => {
		_start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP, ARG0];
			
			$kernel->post(ftpd => 'register');
	    },
		_default => sub {
			my ($kernel, $heap, $event, $arg) = @_[KERNEL, HEAP, ARG0, ARG1];
			return 0 if ($event =~ m/^_/);
			if (ref($arg->[0]) eq 'HASH') {
				my $o = $arg->[0];
				$o->{event} = $event;
			
				# collapse session references to just an id
				foreach (keys %{$o}) {
					if (ref($o->{$_}) eq 'POE::Session') {
						$o->{$_} = $o->{$_}->ID;
					}
				}
				
				# keep some of the logs
				if ($event eq 'ftpd_write_log') {
					$o->{datetime} = localtime();
					if ($#log > 1000) {
						pop(@log);
					}
					push(@log, $o);
				}

				if ($event eq 'ftpd_connected') {
					$conn{$o->{session}} = $o;
				}
				if ($event eq 'ftpd_login') {
					foreach my $z (qw( username password uid gid home)) {
						$conn{$o->{session}}->{$z} = $o->{$z};
					}
				}
				if ($event eq 'ftpd_disconnected') {
					delete $conn{$o->{session}};
				}
				
				# send the data to all connected consoles
				foreach my $c (keys %clients) {
					$kernel->call($c => send => $o);
				}
			} else {
				#print Dump($arg);
				print "unhandled event $event";
			}
			return 0;
		},
		ftpd_registered => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			# put start code here, or use a call in _start like this: $kernel->call(ftpd => 'register');
			# before using ftpd
		},
		ftpd_accept => sub {
			my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

			# allow this ip address?
			if ($data->{peer_addr} eq '10.0.2.1') {
				#print "Connection denied from $data->{peer_addr}:$data->{peer_port} on $data->{local_ip}:$data->{local_port}";
				# disallow
				return 0;
			} else {
				#print "Connection accepted from $data->{peer_addr}:$data->{peer_port} on $data->{local_ip}:$data->{local_port}";
				# allow
				return 1;
			}
			
		},
	},
);

$poe_kernel->run();

