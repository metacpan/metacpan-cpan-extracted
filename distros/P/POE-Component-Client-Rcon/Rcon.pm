package POE::Component::Client::Rcon;

use strict;

use vars qw($VERSION $playerSN);
$VERSION = '0.23';
$playerSN = 0;

use Carp qw(croak);
use Socket;
use Time::HiRes qw(time);
use POE qw(Session Wheel::SocketFactory);

sub DEBUG ()  { 0 };

sub new {
	my $type = shift;
	my $self = bless {}, $type;

	croak "$type requires an event number of parameters" if @_ % 2;

	my %params = @_;

	my $alias = delete $params{Alias};
	$alias = 'rcon' unless defined $alias;

	my $timeout = delete $params{Timeout};
	$timeout = 15 unless defined $timeout and $timeout >= 0;

	my $retry = delete $params{Retry};
	$retry = 2 unless defined $retry and $retry >= 0;

	my $bytes = delete $params{Bytes};
	$bytes = 8192 unless defined $bytes and $bytes > 0;

	croak "$type doesn't know these parameters: ", join(', ', sort(keys(%params))) if scalar(keys(%params));

	POE::Session->create(
		inline_states => {
			_start			=> \&_start,
			rcon			=> \&rcon,
			got_socket		=> \&got_socket,
			got_message		=> \&got_message,
			got_error		=> \&got_error,
			got_challenge		=> \&got_challenge,
			got_rcon_response	=> \&got_rcon_response,
			challenge_timeout	=> \&challenge_timeout,
			rcon_timeout		=> \&rcon_timeout,
			players			=> \&players,
			player_response		=> \&player_response,
			player_parse_hl		=> \&player_parse_hl,
			player_parse_quake	=> \&player_parse_quake,
		},
		args => [ $timeout, $retry, $alias, $bytes ],
	);

	return $self;
}

sub _start {
	my ($kernel, $heap, $timeout, $retry, $alias, $bytes) = @_[KERNEL, HEAP, ARG0..ARG3];
	$heap->{timeout} = $timeout;
	$heap->{retry} = $retry;
	$heap->{bytes} = $bytes;
	$kernel->alias_set($alias);
	print STDERR "Rcon object started.\n" if DEBUG;
}

sub rcon {
	my ($kernel, $heap, $sender, $type, $ip, $port, $pw, $cmd, $postback) = @_[KERNEL, HEAP, SENDER, ARG0..ARG5];
	my ($identifier) = defined($_[ARG6]) ? $_[ARG6] : undef;
	print STDERR "Got $ip:$port with password $pw running command $cmd with postback $postback\n" if DEBUG;
	croak "IP address required to execute an Rcon command" unless defined $ip;
	croak "Port requred to execute an Rcon command" if !defined $port || $port !~ /^\d+$/;
	croak "Password requires to execute an Rcon command" if !defined $pw || $pw eq '';
	croak "Command required to execute an Rcon command" if !defined $cmd || $cmd eq '';
	croak "Server type was not recognized" unless $type =~ /^(?:qw|q2|q3|oldhl|hl)$/;
	my $challenge = '';
	my $wheel = POE::Wheel::SocketFactory->new(
			RemoteAddress	=> $ip,
			RemotePort	=> $port,
			SocketProtocol	=> 'udp',
			SuccessEvent	=> 'got_socket',
			FailureEvent	=> 'got_error',
	);
	$heap->{w_jobs}->{$wheel->ID()} = {
		ip		=> $ip,
		port		=> $port,
		pw		=> $pw,
		cmd		=> $cmd,
		postback	=> $postback,
		session		=> $sender->ID(),
		wheel		=> $wheel,
		identifier	=> $identifier,
		type		=> $type,
		try		=> 1,	# number of tries...
	};
	return undef;
}

sub got_error {
	my ($operation, $errnum, $errstr, $wheel_id, $heap) = @_[ARG0..ARG3,HEAP];
	warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
	delete $heap->{w_jobs}->{$wheel_id}; # shut down that wheel
}

sub got_socket {
	my ($kernel, $heap, $socket, $wheelid) = @_[KERNEL, HEAP, ARG0, ARG3];

	$heap->{jobs}->{$socket} = delete($heap->{w_jobs}->{$wheelid});
	if($heap->{jobs}->{$socket}->{type} eq 'hl') {
		$kernel->select_read($socket, 'got_challenge');
		send($socket, "\xFF\xFF\xFF\xFFchallenge rcon\n\0", 0);
		$heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('challenge_timeout', $heap->{timeout}, $socket);
		print STDERR "Wheel $wheelid got socket and sent rcon challenge\n" if DEBUG;
	} else {
		$kernel->yield('got_challenge', $socket);
	}
}

sub got_challenge {
	my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

	if($heap->{jobs}->{$socket}->{type} eq 'hl') {
		$kernel->alarm_remove($heap->{jobs}->{$socket}->{timer}) if defined $heap->{jobs}->{$socket}->{timer};
		delete($heap->{jobs}->{$socket}->{timer});
		$kernel->select_read($socket);
		recv($socket, my $response = '', 8192, 0);
	
		print STDERR "got_challenge got the response \"$response\" for $socket\n" if DEBUG;
		if($response =~ /challenge +rcon +(\d+)/) {
			$heap->{jobs}->{$socket}->{challenge} = $1;
			$kernel->select_read($socket, 'got_rcon_response');
			send($socket, "\xFF\xFF\xFF\xFFrcon $1 \"" . $heap->{jobs}->{$socket}->{pw} . "\" " . $heap->{jobs}->{$socket}->{cmd} . "\0", 0);
			$heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('rcon_timeout', $heap->{timeout}, $socket);
			print STDERR "Got rcon response and sent rcon command\n" if DEBUG;
		} else {
			$kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback},
					$heap->{jobs}->{$socket}->{type}.
					$heap->{jobs}->{$socket}->{ip},
					$heap->{jobs}->{$socket}->{port},
					$heap->{jobs}->{$socket}->{cmd},
					$heap->{jobs}->{$socket}->{identifier},
					'ERROR: No challenge receieved from server.');
			delete($heap->{jobs}->{$socket});
		}
	} else {
		$kernel->select_read($socket, 'got_rcon_response');
		send($socket, "\xFF\xFF\xFF\xFFrcon \"" . $heap->{jobs}->{$socket}->{pw} . "\" " . $heap->{jobs}->{$socket}->{cmd} . "\0", 0);
		$heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('rcon_timeout', $heap->{timeout}, $socket);
		print STDERR "Got socket and sent rcon command\n" if DEBUG;
	}
}

sub got_rcon_response {
	my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

	$kernel->select_read($socket);
	$kernel->alarm_remove($heap->{jobs}->{$socket}->{timer}) if defined $heap->{jobs}->{$socket}->{timer};
	delete $heap->{jobs}->{$socket}->{timer};
	my $rsock = recv($socket, my $response = '', $heap->{bytes}, 0);

	if($response =~ /bad (?:rconpassword|rcon_password)/i) {
		$kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback},
				$heap->{jobs}->{$socket}->{type},
				$heap->{jobs}->{$socket}->{ip},
				$heap->{jobs}->{$socket}->{port},
				$heap->{jobs}->{$socket}->{cmd},
				$heap->{jobs}->{$socket}->{identifier},
				'ERROR: Bad Rcon password.');
	} else {
		# following regex's thanks to kkrcon
		$response =~ s/\x00+$//;	# terminator
		$response =~ s/^\xff\xff\xff\xffl//;	# new HL
		$response =~ s/^\xff\xff\xff\xffn//;	# qw
		$response =~ s/^\xff\xff\xff\xff//;	# q2/q3
		$response =~ s/^\xfe\xff\xff\xff.....//;	# old hl bug
		$kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback}, 
				$heap->{jobs}->{$socket}->{type},
				$heap->{jobs}->{$socket}->{ip},
				$heap->{jobs}->{$socket}->{port},
				$heap->{jobs}->{$socket}->{cmd},
				$heap->{jobs}->{$socket}->{identifier},
				$response);
		print STDERR "Rcon Response was $response\n" if DEBUG;
	}
	delete($heap->{jobs}->{$socket});
}

sub challenge_timeout {
	my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
	if($heap->{jobs}->{$socket}->{try} > ($heap->{retry} + 1)) {
		$kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback},
				$heap->{jobs}->{$socket}->{type},
				$heap->{jobs}->{$socket}->{ip},
				$heap->{jobs}->{$socket}->{port},
				$heap->{jobs}->{$socket}->{cmd},
				$heap->{jobs}->{$socket}->{identifier},
				'ERROR: Timed out trying to obtain challenge.');
	} else {
		print STDERR "Challenge request timed out for $socket.  Retrying.\n" if DEBUG;
		send($socket, "\xFF\xFF\xFF\xFFchallenge rcon\n\0", 0);
		$heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('challenge_timeout', $heap->{timeout}, $socket);
		$heap->{jobs}->{$socket}->{try}++;
	}
}

sub rcon_timeout {
	my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
	if($heap->{jobs}->{$socket}->{try} > ($heap->{retry} + 1)) {
		$kernel->post($heap->{jobs}->{$socket}->{session}, $heap->{jobs}->{$socket}->{postback},
				$heap->{jobs}->{$socket}->{type},
				$heap->{jobs}->{$socket}->{ip},
				$heap->{jobs}->{$socket}->{port},
				$heap->{jobs}->{$socket}->{cmd},
				$heap->{jobs}->{$socket}->{identifier},
				'ERROR: Timed out waiting for Rcon response.');
	} else {
		print STDERR "Rcon timed out for $socket.  Retrying.\n" if DEBUG;
		send($socket, "\xFF\xFF\xFF\xFFrcon " . $heap->{jobs}->{$socket}->{challenge} . " \"" . $heap->{jobs}->{$socket}->{pw} . "\" " . $heap->{jobs}->{$socket}->{cmd} . "\0", 0) if $heap->{jobs}->{$socket}->{type} =~ /hl$/;
		send($socket, "\xFF\xFF\xFF\xFFrcon \"" . $heap->{jobs}->{$socket}->{pw} . "\" " . $heap->{jobs}->{$socket}->{cmd} . "\0", 0) if $heap->{jobs}->{$socket}->{type} =~ /^(?:q2|q3|qw)$/;
		$heap->{jobs}->{$socket}->{timer} = $kernel->delay_set('rcon_timeout', $heap->{timeout}, $socket);
		$heap->{jobs}->{$socket}->{try}++;
	}
}

sub players {
	my ($kernel, $heap, $sender, $type, $ip, $port, $password, $postback) = @_[KERNEL, HEAP, SENDER, ARG0..ARG4];
	my $identifier = defined($_[ARG5]) ? $_[ARG5] : undef;
	croak "IP address required to execute an Rcon command" unless defined $ip;
	croak "Port requred to execute an Rcon command" if !defined $port || $port !~ /^\d+$/;
	croak "Password requires to execute an Rcon command" if !defined $password || $password eq '';
	croak "Server type was not recognized" unless $type =~ /^(?:qw|q2|q3|oldhl|hl)$/;
	my $jobid = $playerSN;
	$playerSN++;
	print STDERR "Got a request for players at $ip:$port with jobid $jobid\n" if DEBUG;
	$kernel->yield('rcon', $type, $ip, $port, $password, 'status', 'player_response', $jobid);
	$heap->{p_jobs}->{$jobid} = {
		ip		=> $ip,
		port		=> $port,
		pw		=> $password,
		identifier	=> $identifier,
		session		=> $sender->ID(),
		postback	=> $postback,
		type		=> $type,
	};
}

sub player_response {
	my ($kernel, $heap, $jobid, $response) = @_[KERNEL, HEAP, ARG4, ARG5];
	print STDERR "Got a player request response for job $jobid\n" if DEBUG;
	if($response =~ /^ERROR\: /) {
		$kernel->post($heap->{p_jobs}->{$jobid}->{session},
			      $heap->{p_jobs}->{$jobid}->{postback},
			      $heap->{p_jobs}->{$jobid}->{type},
			      $heap->{p_jobs}->{$jobid}->{ip},
			      $heap->{p_jobs}->{$jobid}->{port},
			      $heap->{p_jobs}->{$jobid}->{identifier},
			      $response
			      );	# One of the errors generated from the rcon command...
	} else {
		if($heap->{p_jobs}->{$jobid}->{type} =~ /hl$/) {
			$kernel->yield('player_parse_hl', $jobid, $response);
		} elsif($heap->{p_jobs}->{$jobid}->{type} =~ /^(?:q2|q3|qw)$/) {
			$kernel->yield('player_parse_quake', $jobid, $response);
		}
	}
}

sub player_parse_hl {
	my ($kernel, $heap, $jobid, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
	# This code is partially adapted from KKrcon
	my %players;
	foreach(split(/[\r\n]+/, $response)) {
		if(/^\#[\s\d]\d\s+
		     (?:\")(.+)(?:\")\s+	# Player name
		     (\d+)\s+		# Player ID
		     (\d+)\s+		# WonID
		     ([\d-]+)\s+	# Frag count
		     ([\d:]+)\s+	# time
		     (\d+)\s+		# ping
		     (\d+)\s+		# packetloss
		     (\S+)		# ip:port
		    $/x) {
			$players{$2} = {
				"Name"		=> $1,
				"UserID"	=> $2,
				"WonID"		=> $3,
				"Frags"		=> $4,
				"Time"		=> $5,
				"Ping"		=> $6,
				"Loss"		=> $7,
				"Address"	=> $8,
			};
		}
	}
	$kernel->post($heap->{p_jobs}->{$jobid}->{session},
		      $heap->{p_jobs}->{$jobid}->{postback},
		      $heap->{p_jobs}->{$jobid}->{type},
		      $heap->{p_jobs}->{$jobid}->{ip},
		      $heap->{p_jobs}->{$jobid}->{port},
		      $heap->{p_jobs}->{$jobid}->{identifier},
		      \%players
		      );
	delete($heap->{p_jobs}->{$jobid});
}

sub player_parse_quake {
	my ($kernel, $heap, $jobid, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
	my %players;
	foreach(split(/[\r\n]+/, $response)) {
		if(/^\s*
		    (\d+)\s+		# num
		    ([\d-]+)\s+		# score
		    (\d+)\s+		# ping
		    (.+)		# name
		    \s+(\d+)\s+		# lastmsg
		    (\S+)\s+		# address
		    (\d+)		# qport
		    (?:\s+(\d+)|)	# rate
		   $/x) {
			$players{$1} = {
				"num"		=> $1,
				"score"		=> $2,
				"ping"		=> $3,
				"name"		=> $4,
				"lastmsg"	=> $5,
				"address"	=> $6,
				"qport"		=> $7,
			};
			if(defined($8) && $8 ne '') {
				$players{$1}{"rate"} = $8;
			}
		}
	}
	$kernel->post($heap->{p_jobs}->{$jobid}->{session},
			$heap->{p_jobs}->{$jobid}->{postback},
			$heap->{p_jobs}->{$jobid}->{type},
			$heap->{p_jobs}->{$jobid}->{ip},
			$heap->{p_jobs}->{$jobid}->{port},
			$heap->{p_jobs}->{$jobid}->{identifier},
			\%players
			);
	delete($heap->{p_jobs}->{$jobid});
}
1;

__END__

=head1 NAME

POE::Component::Client::Rcon -- an implementation of the Rcon remote console protocol.

=head1 SYNOPSIS

  use POE qw(Component::Client::Rcon);

  my $rcon = new POE::Component::Client::Rcon(Alias => 'rcon',
		Timeout => 15,
		Retry => 2,
		Bytes => 8192,
		);

  $kernel->post('rcon', 'rcon', 'hl', '127.0.0.1', 27015, 
		  'rcon_password', 'status', 
		  'postback_event', 'identifier');

  $kernel->post('rcon', 'players', 'hl', '127.0.0.1', 27015,
		  'rcon_password',
		  'player_postback_event', 'identifier');

  sub postback_handler {
	  my ($type, $ip, $port, $command, $identifier, $response) = @_;
	  print "Rcon command of $command_executed to a $type server";
	  print " at $ip:$port";
	  print " had a identifier of $identifier" if defined $identifier;
	  print " returned from the server with:\n$response\n";
  }

  sub player_postback_handler {
	  my ($type, $ip, $port, $identifier, $players) = @_;
	  use Data::Dumper;
	  print "Current players at a $type server at $ip:$port";
	  print " with identifier of $identifier" if defined $identifier;
	  print ":\n", Dumper($players);
  }

=head1 DESCRIPTION

POE::Component::Client::Rcon is an implementation of the Rcon protocol -- the protocol
commonly used to remotely administer Half-Life, Quake, and RTCW (Return to Castle 
Wolfenstein) servers.  It is capable of handling multiple Rcon requests simultaneously,
even multiple requests to the same IP/Port simultaneously.  

PoCo::Client::Rcon C<new> can take a few parameters:

=over 2

=item Alias => $alias_name

C<Alias> sets the name of the Rcon component to which you will post events to.  By
default, this is 'rcon'.

=item Timeout => $timeout_in_seconds

C<Timeout> specifies the number of seconds to wait for each step of the Rcon procedure.
The number of steps varies depending on the server being accessed.

=item Retry => $number_of_times_to_retry

C<Retry> sets the number of times PoCo::Client::Rcon should retry Rcon requests.  Since
Rcon is UDP based, there is always the chance of your packets being dropped or lost.
After the number of retries has been exceeded, an error is posted back to the session
you specified to accept postbacks.

=item Bytes => $number_of_bytes_to_postback

C<Bytes> specifies the maximum number of bytes of data you want back from your Rcon command.

=back

=head1 EVENTS

You can send two types of events to PoCo::Client::Rcon.

=over 2

=item rcon

Sends an rcon command to a server and postbacks a response from the server.  Takes six
required parmeters and one optional parameter.

  $kernel->post('rconSession', 'rcon', $typeOfServer, $ip, $port,
	      $password, $command, $postback, $identifier);

After the command has completed, it will post the results back to your postback session with
the format:
  ($typeOfServer, $ip, $port, $command, $identifier, $rconResponseFromServer)

Type of servers currently supported are:


=item B<hl> - Half-Life servers 1.1.0.6 or newer

=item B<oldhl> - Half-Life servers older than 1.1.0.6

=item B<q2> - Quake 2 Server

=item B<q3> - Quake 3 Server

=item B<qw> - QuakeWorld Server


RTCW is supposed to compatible with C<q2>, but it's untested.

C<$identifier> is a scalar that will get passed back to you in your postback.  You
can use it to help you identify the rcon request that is being posted back.  If not 
specified, it will be C<undef>.

=item players

Requests a list of players and player information from the server.  This information is parsed out
of a `status' rcon request.  It takes five required parameters and one optional parameter.

  $kernel->post('rconSession', 'players', $typeOfServer, $ip, $port,
	      $password, $postback, $identifier);

After the command has completed, it will post the results back to your postback session with the format:
  ($typeOfServer, $ip, $port, $identifier, $hashRefOfPlayerInformation)

The type of information contained in the player information hashref will vary depending
on the top of server you are querying.

=over 2

=item Half-Life Player Information

Key is UserID.  Information returned is Name, UserID, WonID, Frags, Time, Ping, Loss, and Address.

=item Quake2 and QuakeWorld Player Information

Key is num.  Information returned is num, score, ping, name, lastmsg, address, and qport.

=item Quake 3 Player Information

Same as Quake2/QuakeWorld, but also includes rate.

=back

=back

=head1 ERRORS

The errors listed below are ones that will be posted back to you in the 'response' field.

=over 2

=item ERROR: Bad Rcon password.

The password you specified was wrong.

=item ERROR: No challenge receieved from server.

In order to hinder hijacking of Rcon connections, Half-Life 1.1.0.6 introduced
a challenge number.  This is obtained as part of the protocol.  This error
simply means that the server did not return a challenge number, and PoCo::Client::Rcon
could not continue.

=item ERROR: Timed out trying to obtain challenge.

Even after retrying, we never receieved an Rcon number.

=item ERROR: Timed out waiting for Rcon response.

Even after retrying, there was no response to your Rcon command.  It could also
mean that the command you executed generated no output.

=back

There are other fatal errors that are handled with croak().

=head1 BUGS

=item
Sorry, I broke compatibility with 0.1...  Quake turned out to be messier to implement than I had 
originally expected.

=item
No tests are distributed with the module yet.

=head1 ACKNOWLEDGEMENTS

=item Rocco Caputo

Wow.. words can't explain how much help he has been.

=item Divo Networks

Thanks for loaning me servers to test against.  They rent game servers
and can be found at http://www.divo.net/ .

=head1 AUTHOR & COPYRIGHTS

POE::Component::Client::Rcon is Copyright 2001-2003 by Andrew A. Chen <achen-poe-rcon@divo.net>
All rights are reserved.  POE::Component::Client::Rcon is free software; you 
may redistribute it and/or modify it under the same terms as Perl itself.

=cut
