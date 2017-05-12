#!/usr/bin/perl

use lib qw(/projects/lib);
use Filesys::Virtual;
use POE qw(Component::Server::FTP);

POE::Session->create(
	inline_states => {
		_start => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];
			POE::Component::Server::FTP->spawn(
				Alias           => 'ftpd',				# ftpd is default
				ListenPort      => 2112,				# port to listen on
				Domain			=> 'blah.net',			# domain shown on connection
				Version			=> 'ftpd '.$POE::Component::Server::FTP::VERSION,			# shown on connection, you can mimic...
				AnonymousLogin	=> 'deny',				# deny, allow
				FilesystemClass => 'Filesys::Virtual::Plain',	# Currently the only one available
				FilesystemArgs  => {
				'root_path' => '/',					# This is actual root for all paths
				'cwd'       => '/',					# Initial current working dir
				'home_path' => '/home',				# Home directory for '~'
				},
				# use 0 to disable these Limits
				DownloadLimit	=> (50 * 1024),			# 50 kb/s per ip/connection (use LimitScheme to configure)
				UploadLimit		=> (100 * 1024),		# 100 kb/s per ip/connection (use LimitScheme to configure)
				LimitScheme		=> 'ip',				# ip or per (connection)
				LogLevel		=> 4,					# 4=debug, 3=less info, 2=quiet, 1=really quiet
				TimeOut			=> 120,					# Idle Timeout
			);
			$kernel->post(ftpd => 'register');
		},
		_stop => sub {
			my ($kernel, $heap) = @_[KERNEL, HEAP];

		},
		_default => sub {
			my ($kernel, $heap, $event, $arg) = @_[KERNEL, HEAP, ARG0, ARG1];
			return 0 if ($event =~ m/^_/);
			if (ref($arg->[0]) eq 'HASH') {
				print "unhandled event $event\n";
				#require Data::Dumper;
				#delete $arg->[0]->{con_session};
				#print Data::Dumper->Dump([$arg])."\n";
			} else {
				print "unhandled event $event\n";
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
				print "connection denied from $data->{peer_addr}:$data->{peer_port} on $data->{local_ip}:$data->{local_port}\n";
				# disallow
				return 0;
			} else {
				print "connection accepted from $data->{peer_addr}:$data->{peer_port} on $data->{local_ip}:$data->{local_port}\n";
				# allow
				return 1;
			}
		},
	},
);
$poe_kernel->run();
