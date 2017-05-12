package POE::Component::Server::FTP::DataSession;

###########################################################################
### POE::Component::Server::FTP::DataSession
### L.M.Orchard (deus_x@pobox.com)
### David Davis (xantus@cpan.org)
###
### TODO:
### -- get rid of *_limit and use params instead
###
### Copyright (c) 2001 Leslie Michael Orchard.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.
###
### Changes Copyright (c) 2003-2004 David Davis and Teknikill Software
###########################################################################

use strict;
use IO::Socket::INET;
use IO::Scalar;
use POE qw(Session Wheel::ReadWrite Filter::Stream Driver::SysRW Wheel::SocketFactory);
use Time::HiRes qw(time);

use Data::Dumper;

# Create a new DataSession

sub new {
	my ($type, $para, $opt) = @_;
	my $self = bless { }, $type;

	my $ses = POE::Session->create(
		 #options =>{ trace=>1 },
		 args => [ $para, $opt ],
		 object_states => [
			$self => {
				_start			=> '_start',
				_stop			=> '_stop',

				_drop			=> '_drop',
				start_LIST		=> 'start_LIST',
				start_NLST		=> 'start_NLST',
				start_STOR		=> 'start_STOR',
				start_RETR		=> 'start_RETR',

				execute			=> 'execute',
				data_send		=> 'data_send',

				data_receive	=> 'data_receive',
				data_flushed	=> 'data_flushed',
				data_error		=> 'data_error',
				data_throttle	=> 'data_throttle',
				data_resume		=> 'data_resume',

				stop_socket		=> 'stop_socket',

				_sock_up		=> '_sock_up',
				_sock_down		=> '_sock_down',

				send_stats		=> 'send_stats',
			}
		],
	);

	return $ses->ID;
}

sub _start {
	my ($kernel, $heap, $para, $opt) = @_[KERNEL, HEAP, ARG0, ARG1];

# generating a port num
#	my $x = pack('n',$port);
#	my $p1 = ord(substr($x,0,1));
#	my $p2 = ord(substr($x,1,1));

	$heap->{send_recv_okay} = 0;
	$heap->{listening} = 0;
	$heap->{rest} = 0;
	$heap->{total_bytes} = 0;
	$heap->{bps} = 0;
	$heap->{send_done} = 0;
	$heap->{type} = 'dl'; # default to download
	$heap->{c_session} = $_[SENDER]->ID;
	%{$heap->{params}} = %{$para};

	if ($opt->{data_port}) {
		$kernel->call($heap->{c_session} => _write_log => 4 => "starting a PORT data session");
		# PORT command
		my ($h1, $h2, $h3, $h4, $p1, $p2) = split(',', $opt->{data_port});

		my $peer_addr = $h1.".".$h2.".".$h3.".".$h4;
		$heap->{port} = ($p1<<8)+$p2;
		$heap->{remote_ip} = $peer_addr;

		$heap->{data} = POE::Wheel::SocketFactory->new(
			SocketDomain => AF_INET,
			SocketType => SOCK_STREAM,
			SocketProtocol => 'tcp',
			RemoteAddress => $peer_addr,
			RemotePort => $heap->{port},
			SuccessEvent => '_sock_up',
			FailureEvent => '_sock_down',
		);

		$heap->{cmd} = $opt->{cmd};
		$heap->{rest} = $opt->{rest} if ($opt->{rest});
		$heap->{filename} = $opt->{filename};
		$heap->{file_path} = $opt->{fs}->{file_path};
	} else {
		$kernel->call($heap->{c_session} => _write_log => 4 => "starting a PASV data session");
		# PASV command
		$heap->{port} = ($opt->{port1}<<8)+$opt->{port2};

		$heap->{data} = POE::Wheel::SocketFactory->new(
			BindAddress    => INADDR_ANY, # Sets the bind() address
			BindPort       => $heap->{port}, # Sets the bind() port
			SuccessEvent   => '_sock_up', # Event to emit upon accept()
			FailureEvent   => '_sock_down', # Event to emit upon error
			SocketDomain   => AF_INET, # Sets the socket() domain
			SocketType     => SOCK_STREAM, # Sets the socket() type
			SocketProtocol => 'tcp', # Sets the socket() protocol
			Reuse          => 'off', # Lets the port be reused
		);

		$heap->{listening} = 1;
		# the command is issued on the next call via
		# a direct post to our session
	}

	$heap->{filesystem} = $opt->{fs};
	$heap->{block_size} = 8 * 1024;
	$heap->{opt} = $opt->{opt};
}

sub _sock_up {
	my ($kernel, $heap, $session, $socket) = @_[KERNEL, HEAP, SESSION, ARG0];

	my $buffer_max = 4 * 1024;
	my $buffer_min = 128;

	$heap->{data} = POE::Wheel::ReadWrite->new(
		Handle			=> $socket,
		Driver			=> POE::Driver::SysRW->new(),
		Filter			=> POE::Filter::Stream->new(),
		InputEvent		=> 'data_receive',
		ErrorEvent		=> 'data_error',
		FlushedEvent	=> 'data_flushed',
		HighMark		=> $buffer_max,
		LowMark			=> $buffer_min,
		HighEvent		=> 'data_throttle',
		LowEvent		=> 'data_resume',
	);

	my ($port, $ip) = (sockaddr_in(getsockname($socket)));
	$heap->{remote_ip} = inet_ntoa($ip);
	$heap->{remote_port} = $port;
	
	$kernel->call($heap->{params}{'Alias'}, notify => ftpd_dcon_connected => {
		dcon_session => $session->ID,
		con_session => $heap->{c_session},
		remote_ip => $heap->{remote_ip},
		port => $heap->{remote_port},
	});

	if ($heap->{listening} == 0) {
		$kernel->call($heap->{c_session} => _write_log => 4 => "data session started for $heap->{cmd} ($heap->{opt})");
		$kernel->yield('start_'.(uc $heap->{cmd}), $heap->{opt});
	} else {
		# TODO check if correct IP connected if that option is on
		$kernel->call($heap->{c_session} => _write_log => 4 => "received connection from $heap->{remote_ip}");
	}
}

sub _sock_down {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	$kernel->call($heap->{c_session} => _write_log => 4 => "socket down");
	delete $heap->{data};
}

sub send_stats {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	$kernel->call($heap->{params}{'Alias'}, notify => ftpd_bps_stats => {
		type => $heap->{type},
		bps => $heap->{bps},
		session => $session->ID,
		con_session => $heap->{c_session},
		remote_ip => $heap->{remote_ip},
		remote_port => $heap->{remote_port},
		xfer_time => $heap->{xfer_time},
		total_bytes => $heap->{total_bytes},
		time => time(),
		send_done => $heap->{send_done},
		rest => $heap->{rest},
		file_size => $heap->{file_size},
		file_stat => $heap->{file_stat},
		filename => $heap->{filename},
		file_path => $heap->{file_path},
	});

	unless ($heap->{send_done} == 1) {
		$kernel->delay_set(send_stats => 2);
	}
}

sub start_LIST {
	my ($kernel, $heap, $dirfile) = @_[KERNEL, HEAP, ARG0];
	my $fs = $heap->{filesystem};

	my $out = "";
	foreach ($fs->list_details($dirfile)) {
		$out .= "$_\r\n";
	}

	$heap->{input_fh} = IO::Scalar->new(\$out);
	$heap->{send_done} = 0;
	$heap->{send_recv_okay} = 1;
	$kernel->yield('execute');
}

sub start_NLST {
	my ($kernel, $heap, $dirfile) = @_[KERNEL, HEAP, ARG0];
	my $fs = $heap->{filesystem};

	my $out = "";
	foreach ($fs->list($dirfile)) {
		$out .= "$_\r\n";
	}

	$heap->{input_fh} = IO::Scalar->new(\$out);
	$heap->{send_done} = 0;
	$heap->{send_recv_okay} = 1;
	$kernel->yield('execute');
}

sub start_RETR {
	my ($kernel, $heap, $fh, $opt) = @_[KERNEL, HEAP, ARG0, ARG1];

	foreach my $f (qw( rest filename )) {
		if (exists($opt->{$f})) {
			$heap->{$f} = $opt->{$f};
		}
	}

	$heap->{file_path} = $heap->{filesystem}->{file_path};
	
	$heap->{input_fh} = $fh;
	$heap->{filesystem}->seek($fh,$heap->{rest},0);

	@{$heap->{file_stat}} = $fh->stat();
	$heap->{file_size} = $heap->{file_stat}[7];

	$heap->{send_done} = 0;
	$heap->{send_recv_okay} = 1;
	$kernel->yield('execute');
}

sub start_STOR {
	my ($kernel, $heap, $fh, $opt) = @_[KERNEL, HEAP, ARG0, ARG1];

	foreach my $f (qw( rest filename )) {
		if (exists($opt->{$f})) {
			$heap->{$f} = $opt->{$f};
		}
	}
	
	$heap->{file_path} = $heap->{filesystem}->{file_path};
	
	$heap->{output_fh} = $fh;
	$heap->{filesystem}->seek($fh,$heap->{rest},0);
	
	@{$heap->{file_stat}} = $fh->stat();
	# not usefull?
	$heap->{file_size} = $heap->{file_stat}[7];
	
	$heap->{type} = 'ul';
	$heap->{send_recv_okay} = 1;
	$heap->{xfer_time} = time();
	$kernel->yield('execute');
}

sub _stop {
#	my $kernel = $_[KERNEL];
}

# Execute the session's pending upload

sub execute {
	my ($kernel, $heap, $session) =	@_[KERNEL, HEAP, SESSION];

	$kernel->yield("send_stats");
	
	if (defined $heap->{input_fh}) {
		$heap->{xfer_time} = time();
		$kernel->yield('data_send');
	} elsif (!defined $heap->{output_fh}) {
		if ($heap->{listening} == 0) {
			$kernel->call($session->ID => '_drop');
		}
	}
}

sub stop_socket {
	my ($kernel, $session, $heap) =	@_[KERNEL, SESSION, HEAP];

	delete $heap->{time_out};

	if (ref($heap->{data}) eq 'POE::Wheel::SocketFactory') {
		# still a factory?! Time to drop connection
		delete $heap->{data};
	}
}

# Send a block to the remote client

sub data_send {
	my ($kernel, $session, $heap) =	@_[KERNEL, SESSION, HEAP];

	if ( (!defined $heap->{input_fh}) || (! ref $heap->{input_fh} ) ) {
		$kernel->call($session->ID => '_drop');
	} elsif ($heap->{send_recv_okay} && (defined $heap->{data})) {

		# if we haven't connected yet, then data will still be a factory
		if (ref($heap->{data}) eq 'POE::Wheel::SocketFactory') {
			$kernel->call($heap->{c_session} => _write_log => 4 => "data is still a SocketFactory (not connected yet?)");
			if (defined $heap->{time_out}) {
				$heap->{time_out} = $kernel->delay_set(stop_socket => 30);
			}
			$kernel->delay_set('data_send' => 2);
			return;
		}

		if (defined $heap->{time_out}) {
			$kernel->alarm_remove($heap->{time_out});
			delete $heap->{time_out};
		}

		$heap->{bps} = ($heap->{total_bytes} / (time() - $heap->{xfer_time}));

		if ($heap->{params}{'DownloadLimit'} > 0) {
			if ($heap->{params}{'LimitSceme'} eq 'ip') {
				if ($kernel->call($heap->{params}{'Alias'} => _bw_limit => 'dl' => $heap->{remote_ip} => $heap->{bps})) {
					$kernel->yield('data_send');
					return;
				}
			} else {
				if ($heap->{bps} > $heap->{params}{'DownloadLimit'}) {
					$kernel->yield('data_send');
					return;
				}
			}
		}

		### Read in a block from the file.
		my $buf;
		my $len = $heap->{input_fh}->read($buf, $heap->{block_size});

		### If something was read, queue it to be sent, and yield
		### back for another data_send.
		if ($len > 0) {
			$heap->{total_bytes} += $len;
			$heap->{data}->put($buf);
			$kernel->yield('data_send');
		} else {
			# If nothing was read, assume EOF, and shut everything down.
			my $fs = $heap->{filesystem};
			$fs->close_read($heap->{input_fh});
			delete $heap->{input_fh};

			$kernel->call($session->ID => '_drop');
		}
	}
}

# Recieve a block from the remote client

sub data_receive {
	my ($kernel, $heap, $session, $data) = @_[KERNEL, HEAP, SESSION, ARG0];

	if ( (!defined $heap->{output_fh}) || (! ref $heap->{output_fh} ) ) {
		$kernel->call($session->ID => '_drop');
	} elsif ($heap->{send_recv_okay} && (defined $heap->{data})) {

		# if we haven't connected yet, then data will still be a factory
		if (ref($heap->{data}) eq 'POE::Wheel::SocketFactory') {
			$kernel->call($heap->{c_session} => _write_log => 4 => "data is still a SocketFactory (not connected yet?)");
			if (defined $heap->{time_out}) {
				$heap->{time_out} = $kernel->delay_set(stop_socket => 30);
			}
			$kernel->delay_set('data_receive' => 1, $data);
			return;
		}

		if (defined $heap->{time_out}) {
			$kernel->alarm_remove($heap->{time_out});
			delete $heap->{time_out};
		}

		$heap->{bps} = ($heap->{total_bytes} / (time() - $heap->{xfer_time}));

		if ($heap->{params}{'UploadLimit'} > 0) {
			if ($heap->{params}{'LimitSceme'} eq 'ip') {
				if ($kernel->call($heap->{params}{'Alias'} => _bw_limit => 'ul' => $heap->{remote_ip} => $heap->{bps})) {
					$kernel->yield('data_receive');
					$heap->{data}->pause_input();
				} else {
					$heap->{data}->resume_input();
				}
			} else {
				if ($heap->{bps} > $heap->{params}{'UploadLimit'}) {
					$kernel->yield('data_receive');
					$heap->{data}->pause_input();
				} else {
					$heap->{data}->resume_input();
				}
			}
		}

		if (defined $data) {
			$heap->{total_bytes} += length($data);

			$heap->{output_fh}->print($data);
		}
	}
}

sub data_error {
	my ($kernel, $heap, $session, $operation, $errnum, $errstr) = @_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];
	my $fs = $heap->{filesystem};

	if ($errnum) {
		$kernel->call($heap->{c_session} => _write_log => 4 => "session with $heap->{remote_ip} : $heap->{port} encountered $operation error $errnum: $errstr");
	} else {
		$kernel->call($heap->{c_session} => _write_log => 4 => "client at $heap->{remote_ip} : $heap->{port} disconnected");
	}

	# either way, stop this session
	if (defined $heap->{output_fh}) {
		$fs->close_write($heap->{output_fh});
		delete $heap->{output_fh};
	}

	if (defined $heap->{input_fh}) {
		$fs->close_read($heap->{input_fh});
		delete $heap->{input_fh};
	}
	
	$heap->{send_done} = 1;
	$kernel->call($session->ID => 'send_stats');
	$kernel->alarm_remove_all();

	delete $heap->{data};
}

sub data_flushed {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
	if ($heap->{send_done} == 1) {
		$kernel->call($session->ID => 'send_stats');
		$kernel->alarm_remove_all();
		$kernel->call($heap->{c_session} => _write_log => 4 => "data flushed, dropping connection");
		delete $heap->{data};
	}
}

sub data_throttle {
	$_[HEAP]->{send_recv_okay} = 0;
}

sub data_resume {
	$_[HEAP]->{send_recv_okay} = 1;
	$_[KERNEL]->yield('data_send');
}

sub _drop {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

	$kernel->alarm_remove_all();
	
	$heap->{send_done} = 1; # for send_stats, so it doesn't delay again
	
	return unless ($heap->{data});

	if (ref($heap->{data}) eq 'POE::Wheel::SocketFactory') {
		# never connected...
		$kernel->call($heap->{c_session} => _write_log => 4 => "Still a SocketFactory in _drop");
		$kernel->call($heap->{c_session} => _write_log => 3 => "Connection timed out");
		delete $heap->{data};
		return;
	}
	
	# if we are fully flushed, go ahead and disconnect
	if ($heap->{data}->get_driver_out_octets() == 0) {
		$kernel->call($heap->{c_session} => _write_log => 4 => "data finished, dropping connection");
		delete $heap->{data};
	} else {
		# if not, then we set a flag and the flushed event
		# drops the connection
		$heap->{send_done} = 1;
	}
}
1;
