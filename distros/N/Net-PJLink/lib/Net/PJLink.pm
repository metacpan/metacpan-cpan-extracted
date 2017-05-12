package Net::PJLink;

use 5.008_001;
use warnings;
use strict;

use Exporter;
use Digest::MD5;
use IO::Socket::INET;
use IO::Select;
use Switch;
use Carp;

# internal constants
use constant {
	PJLINK_PORT	=> 4352,
	PJLINK_C_HEADER	=> '%1',
	PJLINK_A_HEADER	=> 'PJLINK ',
	CONNECT_TIMEOUT	=> 0.05,
	RECEIVE_TIMEOUT	=> 5,
};

our @ISA = qw( Exporter );

=head1 NAME

Net::PJLink - PJLink protocol implementation

=head1 VERSION

Version 1.03

=cut

our $VERSION = '1.03';


=head1 SYNOPSIS

Net::PJLink is a pure perl implementation of the PJLink protocol (L<http://pjlink.jbmia.or.jp/english/>) version 1.00, Class 1.
This is a standard protocol for communicating with network-capable projectors.
Net::PJLink uses an object-oriented style, with an object representing a group of one or more projectors.
An object has methods corresponding to the commands in the PJLink protocol specification.

	use Net::PJLink;

	my $prj = Net::PJLink->new(
		host       => [ '10.0.0.1', '10.0.0.2' ],
		keep_alive => 1,
	);

	$prj->set_power(1); # turn on projectors

	$prj->set_audio_mute(1); # mute sound

	# retreive the current input being used
	my $input = $prj->get_input();
	if ($input->{'10.0.0.1'}->[0] == Net::PJLink::INPUT_RGB) {
		print "RGB input number " . $input->{'10.0.0.1'}->[1];
		print " is active on projector 1.";
	}

	# close network connections to the projectors
	$prj->close_all_connections;

=head1 EXPORTS

Net::PJLink uses constants to represent status codes sent to and received from projectors.
These constants can be used like C<Net::PJLink::ERR_COMMAND>, or imported
into the local namespace by using the Exporter tag C<:RESPONSES>.

	use Net::PJLink qw( :RESPONSES );

	my $prj = Net::PJLink->new(
		host => '192.168.1.10'
	);
	if ($prj->get_power() == POWER_ON) {
		print "Projector is on.";
	}

The two lists below describe each symbol that is exported by the C<:RESPONSES> tag.

=head2 Command Response Constants

These are general status codes that are common to many projector commands.

=over 4

=item * C<OK>

The command succeeded.

=item * C<WARNING>

Status is "warning".

=item * C<ERROR>

Status is "error".

=item * C<ERR_COMMAND>

The command could not be recognized or is not supported by the projector.
This could happen because the projector is deviating from the specification, the message is getting corrupted, or there is a bug in this module.

=item * C<ERR_PARAMETER>

An invalid parameter was given in the command.

=item * C<ERR_UNAVL_TIME>

The command is not available at this time (e.g. projector is on standby, warming up, etc.).

=item * C<ERR_PRJT_FAIL>

A projector failure occurred when processing the command.

=item * C<ERR_NETWORK>

A network connection to the projector could not be established.

=item * C<ERR_AUTH>

Authentication failed.

=item * C<ERR_TIMEOUT>

A response from the projector was not received.

=item * C<ERR_PARSE>

The projector's response was received, but could not be understood.
This could happen because the projector is deviating from the specification, the message is getting corrupted, or there is a bug in this module.

=back

=cut

use constant {
	OK		=>  0,	#'OK',
	ERR_COMMAND	=> -1,	#'ERR1',
	ERR_PARAMETER	=> -2,	#'ERR2',
	ERR_UNAVL_TIME	=> -3,	#'ERR3',
	ERR_PRJT_FAIL	=> -4,	#'ERR4',
	ERR_NETWORK	=> -5,
	ERR_AUTH	=> -6,
	WARNING		=> -7,
	ERROR		=> -8,
	ERR_TIMEOUT	=> -9,
	ERR_PARSE	=> -10,
};

=head2 Status Responses

These values are returned from commands that request information from the projector.
See the documentation for each command to find out which values can be returned for that command.

=over 4

=item * C<POWER_OFF>

=item * C<POWER_ON>

=item * C<POWER_COOLING>

=item * C<POWER_WARMUP>

=item * C<INPUT_RGB>

=item * C<INPUT_VIDEO>

=item * C<INPUT_DIGITAL>

=item * C<INPUT_STORAGE>

=item * C<INPUT_NETWORK>

=item * C<MUTE_VIDEO>

=item * C<MUTE_AUDIO>

=back

=cut

use constant {
	POWER_OFF	=> 0,
	POWER_ON	=> 1,
	POWER_COOLING	=> 2,
	POWER_WARMUP	=> 3,
	INPUT_RGB	=> 1,
	INPUT_VIDEO	=> 2,
	INPUT_DIGITAL	=> 3,
	INPUT_STORAGE	=> 4,
	INPUT_NETWORK	=> 5,
	MUTE_VIDEO	=> 1,
	MUTE_AUDIO	=> 2,
};

our @EXPORT_OK = qw(
	POWER_OFF POWER_ON POWER_COOLING POWER_WARMUP
	INPUT_RGB INPUT_VIDEO INPUT_DIGITAL INPUT_STORAGE INPUT_NETWORK
	MUTE_VIDEO MUTE_AUDIO
	ERR_COMMAND ERR_PARAMETER ERR_UNAVL_TIME ERR_PRJT_FAIL ERR_NETWORK ERR_AUTH
	OK WARNING ERROR ERR_TIMEOUT ERR_PARSE
);
our %EXPORT_TAGS = (
	RESPONSES => [qw(
		POWER_OFF POWER_ON POWER_COOLING POWER_WARMUP
		INPUT_RGB INPUT_VIDEO INPUT_DIGITAL INPUT_STORAGE INPUT_NETWORK
		MUTE_VIDEO MUTE_AUDIO
		ERR_COMMAND ERR_PARAMETER ERR_UNAVL_TIME ERR_PRJT_FAIL ERR_NETWORK ERR_AUTH
		OK WARNING ERROR ERR_TIMEOUT ERR_PARSE
	)]
);


# used internally
# list of command codes
my %COMMAND = (
	power		=> 'POWR',
	input		=> 'INPT',
	mute		=> 'AVMT',
	status		=> 'ERST',
	lamp		=> 'LAMP',
	input_list	=> 'INST',
	name		=> 'NAME',
	mfr		=> 'INF1',
	prod_name	=> 'INF2',
	prod_info	=> 'INFO',
	class		=> 'CLSS',
);

# used internally
# response codes that are translated
# into constants for all command responses
my %RESPONSE = (
	'OK'		=> OK,
	'ERR1'		=> ERR_COMMAND,
	'ERR2'		=> ERR_PARAMETER,
	'ERR3'		=> ERR_UNAVL_TIME,
	'ERR4'		=> ERR_PRJT_FAIL,
);

=head1 UTILITY METHODS

=head2 new(...)

	use Net::PJLink;

	# Send commands to two hosts (batch mode),
	# don't close the connection after each command,
	# if a host cannot be contacted then remove it,
	# wait up to 1 second for a connection to be opened
	my $prj = Net::PJLink->new(
		host		=> ['10.0.0.1', '10.0.0.2'],
		try_once	=> 1,
		keep_alive	=> 1,
		connect_timeout	=> 1.0,
	);

Constructor for a new PJLink object.
It requires at least the C<host> option to indicate where commands should be sent.
The full list of arguments:

=over 4

=item * host

This can be either a string consisting of a hostname or an IP address, or an array of such strings.
If you want to add a whole subnet, use something like L<Net::CIDR::Set> to expand CIDR notation to an array of IP addresses.
Every command given to this object will be applied to all hosts, and replies will be returned in a hash indexed by hostname or IP address if more than one host was given.

=item * try_once

True/False. Default is false.
Automatically remove unresponsive hosts from the list of hosts.
This speeds up any subseqent commands that are issued by not waiting for network timeout on a host that is down.
If this option evaluates false, the list of hosts will never be automatically changed.

=item * batch

True/False.
Force "batch mode" to be enabled or disabled.
Batch mode is normally set automatically based on whether multiple hosts are being used.
With batch mode on, all results will be returned as a hash reference indexed by hostname or IP address.
If batch mode is disabled when commands are sent to multiple hosts, only one of the hosts' results will be returned (which one is unpredictable).

=item * port

Default is 4352, which is the standard PJLink port.
Connections will be made to this port on each host.

=item * auth_password

Set the password that will be used for authentication for those hosts that require it. 
It must be 32 alphanumeric characters or less.
The password is not transmitted over the network; it is used to calculate an MD5 sum.

=item * keep_alive

True/False. Default is false.
If set, connections will not be closed automatically after a response is received.
This is useful when sending many commands.

=item * connect_timeout

The time (in seconds) to wait for a new TCP connection to be established.
Default is 0.5.
This may need to be changed, depending on your network and/or projector.
The default should provide good reliability, and be practical for a small number of projectors.
Using a value of 0.05 seems to work well for connecting to a large number of hosts over a fast network in a reasonable amount of time.
(Larger values can take a long time when connecting to each host in a /24 subnet.)

=item * receive_timeout

The time (in seconds) to wait for a reply to be received.
If this option is not specified, a default of 5 seconds is used.
The value needed here might vary greatly between different projector models.

=back

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	my %args = @_;

	unless (defined $args{'host'}) {
		carp "Missing 'host' argument";
		return undef;
	}
	switch (ref $args{'host'}) {
		case '' {
			$self->{'host'} = {$args{'host'} => 0};
		}
		case 'ARRAY' {
			foreach (@{$args{'host'}}) {$self->{'host'}->{$_} = 0;}
		}
		else {
			carp "Invalid 'host' argument";
			return undef;
		}
	}
	$self->{'batch'} = (scalar keys %{$self->{'host'}} > 1);
	$self->{'try_once'} = $args{'try_once'} ? 1 : 0;
	$self->{'batch'} = $args{'batch'} if (defined $args{'batch'});
	$self->{'port'} = $args{'port'} || PJLINK_PORT;
	$self->{'keep_alive'} = $args{'keep_alive'} ? 1 : 0;
	$self->{'auth_password'} = $args{'auth_password'} if (defined $args{'auth_password'});
	$self->{'connect_timeout'} = $args{'connect_timeout'} || CONNECT_TIMEOUT;
	$self->{'receive_timeout'} = $args{'receive_timeout'} || RECEIVE_TIMEOUT;
	return $self;
}

# internal method
# Open a TCP connection
sub _open_connection {
	my $self = shift;
	my $host = shift;

	if ($self->{'host'}->{$host}) {
		warn "Re-opening connection to $host";
		$self->{'host'}->{$host}->close;
	}
	my $socket = IO::Socket::INET->new(
		PeerAddr => $host,
		PeerPort => $self->{'port'},
		Proto    => 'tcp',
		Timeout  => $self->{'connect_timeout'},
	);
	return 0 unless ($socket && $socket->connected);
	$socket->autoflush(1);
	$self->{'host'}->{$host} = $socket;
	return $socket;
}

# internal method
# Check authentication status on a just-opened PJLink connection.
# If necessary, use auth_password to authenticate the connection.
sub _auth_connection {
	my $self = shift;
	my $host = shift;
	my $resp;

	# undef if unknown host
	return undef unless ($self->{'host'}->{$host});
	my $cnx = $self->{'host'}->{$host};
	$cnx->recv($resp, 128);
	# false, unless format is correct
	return 0 unless (defined $resp && $resp =~ /^PJLINK ([01])( ([0-9a-fA-F]+))?\x0d$/);
	# true, no auth required
	return 1 if ($1 == 0);
	# false, unless password is given
	return 0 unless (defined $self->{'auth_password'});
	# false, unless random number was received
	return 0 unless ($3);

	my $digest = Digest::MD5::md5_hex($3 . $self->{'auth_password'});
	# test command to verify that auth succeeded
	$cnx->send($digest . "%1POWR ?\xd");
	$cnx->recv($resp, 32);
	return 1 if (defined $resp && $resp =~ /^%1POWR=\d\x0d$/);
	# don't close the connection yet,
	# because auth might be tried with a
	# different password
	return 0;
}

=head2 set_auth_password($pass)

Set the password that will be used when connecting to a projector.
This will only apply to newly established connections.

	$prj->set_auth_password('secret');

Returns 1 if successful, 0 otherwise (password is too long).

=cut

sub set_auth_password {
	my $self = shift;
	my $pass = shift;
	if (defined $pass && $pass !~ /^.{1,32}$/) {
		carp "auth_password must be less than or equal to 32 bytes";
		return 0;
	} else {
		$self->{'auth_password'} = $pass;
		return 1;
	}
}

=head2 close_connection($host)

Manually close the connection to one host, specified by hostname or IP address.
Returns 1 if the connection was found and closed, returns 0 otherwise.

=cut

sub close_connection {
	my $self = shift;
	my $host = shift;

	return 0 unless (defined $self->{'hosts'}->{$host});
	$self->{'hosts'}->{$host}->close;
	return 1;
}

=head2 close_all_connections()

Manually close all open connections that are managed by this instance.
This is usually used when the object has been created with the C<keep_alive> option.

=cut

sub close_all_connections {
	my $self = shift;
	foreach (values %{$self->{'hosts'}}) { $_->close if ($_); }
}

# internal method
# Build the command message and do some basic sanity
# checks on it.
sub _build_command {
	my $self = shift;
	my $cmd = shift;
	my $arg = shift;
	die("Invalid command name \"$cmd\"!") unless (defined $COMMAND{$cmd});
	die("Invalid characters in command argument!") if ($arg =~ /\x0d/);
	return PJLINK_C_HEADER . $COMMAND{$cmd} . ' ' . $arg . "\xd";
}

# internal method
# Build and send a command string to all active hosts.
# The data must be sent separately to each host because
# the PJLink protocol requires the use of TCP connections.
# This code sends data to each host, then receives responses
# from each host. This is probably not the best way to handle
# the problem, and it will not work well with multiple
# hundreds of hosts (especially when many hosts are not
# reachable and thus cause a network timeout delay). This is
# because the first connections to be opened will timeout
# due to inactivity before the data can be received.
# Suggestions are welcome.
sub _send_command {
	my $self = shift;
	my $cmd = shift;
	my $arg = shift;
	local $/ = "\xd";
	my(%result, %name);
	my $payload = $self->_build_command($cmd, $arg);
	my $select = IO::Select->new();
	# send loop: try to connect to each host and send data
	while (my($host, $cnx) = each %{$self->{'host'}}) {
		$result{$host} = ERR_TIMEOUT;
		unless ($cnx) {
			unless ($cnx = $self->_open_connection($host)) {
				$result{$host} = ERR_NETWORK;
				delete $self->{'host'}->{$host} if ($self->{'try_once'});
				next;
			}
			unless ($self->_auth_connection($host)) {
				$result{$host} = ERR_AUTH;
				delete $self->{'host'}->{$host} if ($self->{'try_once'});
				next;
			}
		}
		$cnx->write($payload);
		$select->add($cnx);
		$name{$cnx} = $host;
	}
	# recv loop: check connections for responses until 5 second timeout
	my $start_time = time;
	while ($select->count() && time - $start_time < $self->{'receive_timeout'}) {
		my @ready = $select->can_read($self->{'receive_timeout'});
		foreach my $cnx (@ready) {
			my $host = $name{$cnx};
			my $resp;
			my $status = $cnx->recv($resp, 256, MSG_DONTWAIT);
			next unless (defined $status);
			$select->remove($cnx);
			unless ($self->{'keep_alive'}) {
				$cnx->close;
				$self->{'host'}->{$host} = 0;
			}
			my $cmd_symbol = $COMMAND{$cmd};
			if (defined $resp && $resp =~ /^%1$cmd_symbol=(.*)\x0d$/) {
				if (defined $RESPONSE{$1}) {
					$result{$host} = $RESPONSE{$1};
				} else {
					$result{$host} = $1;
				}
			} else {
				$result{$host} = ERR_PARSE;
			}
		}
	}
	# return data
	if ($self->{'batch'}) {
		return \%result;
	} else {
		(undef, my $result) = each %result;
		return $result;
	}
}

=head2 add_hosts($host1, ...)

Takes arguments of the same form as the C<host> option to the C<new> constructor.
These hosts will be appended to the list of hosts that commands will be sent to.
Batch mode is enabled if appropriate.

=cut

sub add_hosts {
	my $self = shift;
	foreach my $host (@_) {
		switch (ref $host) {
			case '' {
				$self->{'host'}->{$host} = 0;
			}
			case 'ARRAY' {
				foreach (@{$host}) {$self->{'host'}->{$_} = 0;}
			}
			else {
				carp "Invalid argument";
			}
		}
	}
	$self->{'batch'} = (scalar keys %{$self->{'host'}} > 1);
}

=head2 remove_hosts($host1, ...)

Takes arguments of the same form as the C<host> option to the C<new> constructor.
These hosts will be removed from the list of hosts that commands will be sent to.
Batch mode is not changed by this function in order to avoid a surprise change in output format.

=cut

sub remove_hosts {
	my $self = shift;
	foreach my $host (@_) {
		switch (ref $host) {
			case '' {
				delete $self->{'host'}->{$host};
			}
			case 'ARRAY' {
				foreach (@{$host}) {delete $self->{'host'}->{$_};}
			}
			else {
				carp "Invalid argument";
			}
		}
	}
}

=head1 PROJECTOR COMMAND METHODS

These methods are all frontends for projector commands; calling them will issue the corresponding command immediately.
The actual return value of these functions depends on whether batch mode is enabled (it is automatically enabled when more than one host has been added).
If enabled, the return value of these functions will always be a hash reference, with the keys being hostnames or IP addresses and the values being the response received from that host.
To illustrate:

	$prj = Net::PJLink->new(host => '10.0.0.1');

	$prj->set_power(1);
	# => 0

	$prj->add_hosts('10.0.0.2');

	$prj->set_power(1);
	# => { '10.0.0.1' => 0, '10.0.0.2' => 0 }

The return values described below for each method are the return values for each host.

=head2 set_power($state)

Turn power on or off.
If the single argument is true, turn on; if argument is false, turn off.
Returns one of C<OK>, C<ERR_PARAMETER>, C<ERR_UNAVL_TIME>, C<ERR_PRJT_FAIL>.

=cut

sub set_power {
	my $self = shift;
	my $status = ($_[0] ? '1' : '0');
	return $self->_send_command('power', $status);
}

=head2 get_power()

Get the power status.
Returns one of C<POWER_OFF>, C<POWER_ON>, C<POWER_COOLING>, C<POWER_WARMUP>, C<ERR_UNAVL_TIME>, or C<ERR_PRJT_FAIL>.

=cut

sub get_power {
	my $self = shift;
	return $self->_send_command('power', '?');
}

=head2 set_input($input_type, $number)

Set the active input.
The first argument is the input type, which can be specified using one of the provided values:

=over 4

=item * C<INPUT_RGB>

=item * C<INPUT_VIDEO>

=item * C<INPUT_DIGITAL>

=item * C<INPUT_STORAGE>

=item * C<INPUT_NETWORK>

=back

The second argument specifies which of the inputs of that type should be used.
For example, to use the second video input:

	$prj->set_input(Net::PJLink::INPUT_VIDEO, 2);

See the C<get_input_list()> method for information on available inputs.
Returns one of C<OK>, C<ERR_PARAMETER>, C<ERR_UNAVL_TIME>, or C<ERR_PRJT_FAIL>.

=cut

sub set_input {
	my $self = shift;
	my $value = shift;
	my $number = shift;
	unless ($value =~ /^[1-9]$/ && $number =~ /^[1-9]$/) {
		carp "Invalid argument";
		return 0;
	}
	return $self->_send_command('input', "$value$number");
}

=head2 get_input()

Get the current active input.
An array reference is returned, with the first value being the input type and the second value indicating which input of that type.
Example:

	$prj->get_input();
	# => [ 3, 1 ]

The example response indicates that the first C<INPUT_DIGITAL> source is active.

=cut

sub get_input {
	my $self = shift;
	my $xform = sub {
		local $_ = shift;
		return $_ unless (/(\d)(\d)/);
		return [$1, $2];
	};
	my $resp = $self->_send_command('input', '?');
	if (not $self->{'batch'}) { return &$xform($resp); }
	foreach (keys %$resp) { $resp->{$_} = &$xform($resp->{$_}); }
	return $resp;
}

=head2 set_audio_mute($state)

Set audio mute on or off.
Returns one of C<OK>, C<ERR_PARAMETER>, C<ERR_UNAVL_TIME>, or C<ERR_PRJT_FAIL>.

=cut

sub set_audio_mute {
	my $self = shift;
	my $value = ($_[0] ? '1' : '0');
	return $self->_send_command('mute', '2' . $value);
}

=head2 set_video_mute($state)

Set video mute on or off.
Returns one of C<OK>, C<ERR_PARAMETER>, C<ERR_UNAVL_TIME>, or C<ERR_PRJT_FAIL>.

=cut

sub set_video_mute {
	my $self = shift;
	my $value = ($_[0] ? '1' : '0');
	return $self->_send_command('mute', '1' . $value);
}

=head2 get_av_mute()

Get the current status of audio and video mute.
An array reference is returned, with the first value being audio mute and the second being video mute.
If the command failed, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_av_mute {
	my $self = shift;
	my $xform = sub {
		local $_ = shift;
		return $_ unless (/([123])([01])/);
		switch ($1) {
			case 1 { return [1-$2, $2]; }
			case 2 { return [$2, 1-$2]; }
			case 3 { return [$2, $2]; }
		}
	};
	my $resp = $self->_send_command('mute', '?');
	if (not $self->{'batch'}) { return &$xform($resp); }
	foreach (keys %$resp) { $resp->{$_} = &$xform($resp->{$_}); }
	return $resp;
}

=head2 get_status()

Get the health status of various parts of the projector.
A hash reference is returned, with the keys being the name of the part.

	$prj->get_status();
	# => {
	#	'fan'	=> 0,
	#	'lamp'	=> 0,
	#	'temp'	=> 0,
	#	'cover'	=> 0,
	#	'filter'=> -7,
	#	'other'	=> 0,
	# }

The example response indicates that the projector's filter is in a C<WARNING> state, and all other areas are C<OK>.

The values will be one of C<OK>, C<WARNING>, or C<ERROR>.

Example for finding lamp health from multiple projectors:

	my $prj = Net::PJLink->new(
		host => [ '192.168.1.1', '192.168.1.2' ],
	);

	my $result = $prj->get_status();
	while (my($host, $status) = each %$result) {
		my $lamp = $status->{'lamp'};
		print "The projector at $host has lamp status: ";
		print $lamp == OK ? "ok\n" :
		      $lamp == WARNING ? "warning\n" :
		      $lamp == ERROR ? "error\n";
	}

=cut

sub get_status {
	my $self = shift;
	my $xform = sub {
		local $_ = shift;
		my %xlate = (
			'0'	=> OK,
			'1'	=> WARNING,
			'2'	=> ERROR,
		);
		return $_ unless (/(\d)(\d)(\d)(\d)(\d)(\d)/);
		return {
			'fan'	=> $xlate{$1},
			'lamp'	=> $xlate{$2},
			'temp'	=> $xlate{$3},
			'cover'	=> $xlate{$4},
			'filter'=> $xlate{$5},
			'other'	=> $xlate{$6},
		};
	};
	my $resp = $self->_send_command('status', '?');
	if (not $self->{'batch'}) { return &$xform($resp); }
	foreach (keys %$resp) { $resp->{$_} = &$xform($resp->{$_}); }
	return $resp;
}

=head2 get_lamp_info()

Get the status and hours used for each lamp. The return value is a data structure like:

	[
		[ $status, $hours ],
		... # each lamp
	]

For consistency, this structure is used even if the projector only has one lamp.

C<$status> indicates whether the lamp is on or off (1 or 0). $hours is an integer indicating the total number of hours the lamp has been on.
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_lamp_info {
	my $self = shift;
	my $xform = sub {
		local $_ = shift;
		return $_ unless (/((\d+)\s+([10]))+/);
		my @lamps = split / /;
		my @ret;
		while (scalar @lamps) {
			my($hours, $status) = splice @lamps, 0, 2;
			push @ret, [$status, $hours];
		}
		return \@ret;
	};
	my $resp = $self->_send_command('lamp', '?');
	if (not $self->{'batch'}) { return &$xform($resp); }
	foreach (keys %$resp) { $resp->{$_} = &$xform($resp->{$_}); }
	return $resp;
}

=head2 get_input_list()

Get a list of all available inputs. The return value is a data structure like:

	[
		[ $type, $index ],
		... # each input
	]

C<$type> corresponds to one of the five input types:

=over 4

=item * C<INPUT_RGB>

=item * C<INPUT_VIDEO>

=item * C<INPUT_DIGITAL>

=item * C<INPUT_STORAGE>

=item * C<INPUT_NETWORK>

=back

C<$index> is the number of that type (i.e. C<[3, 3]> indicates the third digital input).
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_input_list {
	my $self = shift;
	my $xform = sub {
		local $_ = shift;
		return $_ if (/^-?\d+$/);
		return ERR_PARSE unless (/[1-5][1-9]( [1-5][1-9])*/);
		my @inputs = split / /;
		my @ret;
		while (scalar @inputs) {
			my $inp = shift @inputs;
			$inp =~ /(\d)(\d)/;
			push @ret, [$1, $2];
		}
		return \@ret;
	};
	my $resp = $self->_send_command('input_list', '?');
	if (not $self->{'batch'}) { return &$xform($resp); }
	foreach (keys %$resp) { $resp->{$_} = &$xform($resp->{$_}); }
	return $resp;
}

=head2 get_name()

Get the projector name. Returns a string.
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_name {
	my $self = shift;
	return $self->_send_command('name', '?');
}

=head2 get_manufacturer()

Get the manufacturer name. Returns a string.
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_manufacturer {
	my $self = shift;
	return $self->_send_command('mfr', '?');
}

=head2 get_product_name()

Get the product name. Returns a string.
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_product_name {
	my $self = shift;
	return $self->_send_command('prod_name', '?');
}

=head2 get_product_info()

Get "other information". Returns a string.
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_product_info {
	my $self = shift;
	return $self->_send_command('prod_info', '?');
}

=head2 get_class()

Get information on supported PJLink Class. Returns a single digit.
For example, returning "2" indicates that the projector is compatible with the PJLink Class 2 protocol.
The PJLink v.1.00 Class 1 specification only defines return values "1" and "2".
If the command was not successful, C<ERR_UNAVL_TIME> or C<ERR_PRJT_FAIL> may be returned.

=cut

sub get_class {
	my $self = shift;
	return $self->_send_command('class', '?');
}

=head1 AUTHOR

Kyle Emmons, C<< <kemmons at tma-0.net> >>

=head1 BUGS

This module has only been tested on Panasonic PTFW100NTU projectors.

The code for opening network connections may not work reliably for a large (~200) number of hosts.
This is due to network connections timing out before all hosts have been contacted.
If you encounter this problem, adjusting the C<connect_timeout> and C<receive_timeout> arguments may help.

Please report any bugs or feature requests to C<bug-net-pjlink at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PJLink>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PJLink


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PJLink>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PJLink>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PJLink>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PJLink/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Kyle Emmons.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The PJLink name is a trademark of Japan Business Machine and Information System Industries Association (JBMIA).

=cut

1; # End of Net::PJLink
