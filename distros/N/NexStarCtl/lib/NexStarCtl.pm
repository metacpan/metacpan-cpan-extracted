#!/usr/bin/perl

########################################################
# NexStarCtl - NexStar control library
# 
# 
#		     (c)2013-2016 by Rumen G.Bogdanovski
########################################################

=head1 NAME

 NexStarCtl - API to control NexStar compatible telescopes

=head1 SYNOPSIS

 use NexStarCtl;
 
 my $port = open_telescope_port("/dev/XXX"); 
 if (!defined $port) {
	print "Can not open communication port.\n";
	exit;
 }
 
 # check if the mount is aligned
 if (tc_check_align($port)) {
 	print "The telescope is aligned.\n";
 } else {
 	print "The telescope is not aligned.\n";
 }
 
 # Read the stored coordinates of the location
 my ($lon,$lat) = tc_get_location_str($port);
 if (! defined($lon)) {
 	print "Telescope did not respond\n";
 	close_telescope_port($port);
 	exit;
 }
 print "Location coordinates:\n LON=$lon\n LAT=$lat\n";

 my ($date,$time,$tz,$dst) = tc_get_time_str($port);
 # ...
 # Do some other stuff
 # ...
 
 close_telescope_port($port);

=head1 DESCRIPTION

This module implements the serial commands supported by the Celestron NexStar hand control (HC) and SkyWatcher/Orion SynScan HC.
This applies to the Celestron: NexStar GPS, NexStar GPS-SA, NexStar iSeries, NexStar SE Series, NexStar GT, CPC, SLT, Advanced-VX,
Advanced-GT, CGE, CGEM etc. SkyWatcher: EQ5, HEQ5, EQ6 (Pro), AZ-EQ5 GT, AZ-EQ6 GT, EQ8 etc. and the corresponding Orion mounts.

Communication to the hand control is 9600 bits/sec, no parity and one stop bit via the RS-232 port on the base of the
hand control.

Communication can be established over TCP/IP if nexbridge is running on the computer connected to the telescope.

For extended example how to use this perl module look in to the distribution folder for  nexstarctl/nexstarctl.pl.
This program is a complete console tool to control NexStar telescopes based on NexStarCtl module.

NOTE: For SkyWatcher/Orion mounts it is highly recommended to enforce protocol version checking (see enforce_protocol_version()) as
the AUX commands are not supported or may behave erratically.

=cut

package NexStarCtl;

use POSIX;
use Time::Local;
use IO::Socket::INET;
use strict;
use Exporter;

if ($^O eq "MSWin32") {
	eval "use Win32::SerialPort"; die $@ if $@;
} else {
	eval "use Device::SerialPort"; die $@ if $@;
}

use constant {
	VER_1_2    => 0x10200,
	VER_1_6    => 0x10600,
	VER_2_2    => 0x20200,
	VER_2_3    => 0x20300,
	VER_3_1    => 0x30100,
	VER_4_10   => 0x40A00,
	VER_4_37_8 => 0x042508,
	# All protocol versions
	VER_AUX  => 0xFFFFFF,
	# Auto detect version by HC
	VER_AUTO => 0x0,

	# Protocol vendors
	VNDR_CELESTRON     => 0x1,
	VNDR_SKYWATCHER    => 0x2,
	VNDR_ALL_SUPPORTED => 0x3,   # VNDR_CELESTRON | VNDR_SKYWATCHER

	# version manipulation
	RELEASE_MASK  => 0xFF0000,
	REVISION_MASK => 0x00FF00,
	PATCH_MASK    => 0x0000FF
};


my $is_tcp = 0;
my $proto_version = VER_AUX;
my $mount_vendor = VNDR_ALL_SUPPORTED;

# There is no way to tell SkyWatcher from Celestron. Unfortunately both share the
# same IDs and some Celestron mounts have RTC wile SW does not. That is why the user
# should decide. Set use_rtc to 1 to enable using the RTC on the mounts that have RTC.
our $use_rtc = 0;

#  0 => no error
# -5 => unsupported command
our $error = 0;

use constant TIMEOUT => 4;

our @ISA = qw(Exporter);
our @EXPORT = qw( 
	VERSION

	use_rtc
	error
	VER_1_2 VER_1_6 VER_2_2 VER_2_3
	VER_3_1 VER_4_10 VER_4_37_8 VER_AUX VER_AUTO

	VNDR_CELESTRON VNDR_SKYWATCHER

	DEG2RAD RAD2DEG 
	notnum precess round 
	d2hms d2dms d2dm dms2d hms2d
	dd2nex dd2pnex nex2dd pnex2dd

	get_model_name

	open_telescope_port 
	close_telescope_port
	read_telescope 
	enforce_protocol_version
	guess_mount_vendor
	enforce_vendor_protocol

	tc_pass_through_cmd
	tc_check_align tc_get_orientation
	tc_goto_rade tc_goto_rade_p
	tc_goto_azalt tc_goto_azalt_p
	tc_get_rade tc_get_rade_p
	tc_get_azalt tc_get_azalt_p
	tc_sync_rade tc_sync_rade_p
	tc_goto_in_progress tc_goto_cancel
	tc_get_model 
	tc_get_version
	tc_echo
	tc_get_location tc_get_location_str
	tc_get_time tc_get_time_str
	tc_set_time tc_set_location
	tc_get_tracking_mode tc_set_tracking_mode
	tc_slew_variable tc_slew_fixed
	tc_get_autoguide_rate tc_set_autoguide_rate
	tc_get_backlash tc_set_backlash

	TC_TRACK_OFF
	TC_TRACK_ALT_AZ
	TC_TRACK_EQ_NORTH
	TC_TRACK_EQ_SOUTH
	TC_TRACK_EQ
	TC_TRACK_EQ_PEC

	TC_DIR_POSITIVE
	TC_DIR_NEGATIVE

	TC_AXIS_RA_AZM
	TC_AXIS_DE_ALT	
);

our $VERSION = "0.15";

use constant {
	NX_TC_TRACK_OFF => 0,
	NX_TC_TRACK_ALT_AZ => 1,
	NX_TC_TRACK_EQ_NORTH => 2,
	NX_TC_TRACK_EQ_SOUTH => 3,

	SW_TC_TRACK_OFF => 0,
	SW_TC_TRACK_ALT_AZ => 1,
	SW_TC_TRACK_EQ => 2,
	SW_TC_TRACK_EQ_PEC => 3,

	TC_TRACK_OFF => 0,
	TC_TRACK_ALT_AZ => 1,
	TC_TRACK_EQ_NORTH => 2,
	TC_TRACK_EQ_SOUTH => 3,
	TC_TRACK_EQ => 4,
	TC_TRACK_EQ_PEC => 5,
	
	TC_DIR_POSITIVE => 1,
	TC_DIR_NEGATIVE => 0,
	
	TC_AXIS_RA_AZM => 1,
	TC_AXIS_DE_ALT => 0,
	
	_TC_DIR_POSITIVE => 6,
	_TC_DIR_NEGATIVE => 7,
	
	_TC_AXIS_RA_AZM => 16,
	_TC_AXIS_DE_ALT => 17,

	DEG2RAD => 3.1415926535897932384626433832795/180.0,
	RAD2DEG => 180.0/3.1415926535897932384626433832795
};

my %mounts = (
	&VNDR_CELESTRON => {
		1 => "NexStar GPS Series",
		3 => "NexStar i-Series",
		4 => "NexStar i-Series SE",
		5 => "CGE",
		6 => "Advanced GT",
		7 => "SLT",
		9 => "CPC",
		10 => "GT",
		11 => "NexStar 4/5 SE",
		12 => "NexStar 6/8 SE",
		14 => "CGEM",
		20 => "Advanced VX",
		22 => "Nexstar Evolution"},
	&VNDR_SKYWATCHER => {
		0 => "EQ6 Series",
		1 => "HEQ5 Series",
		2 => "EQ5 Series",
		3 => "EQ3 Series",
		4 => "EQ8 Series",
		5 => "AZ-EQ6 Series",
		6 => "AZ-EQ5 Series",
		160 => "AllView Series",
		( map { $_ => "AZ Series" } (128..143)),
		( map { $_ => "DOB Series" } (144..159))

	}
);

sub release_before($) {
	my ($release) = @_;

	if ((($proto_version & RELEASE_MASK) >> 16) < $release) {
		$error = -5;
	} else {
		$error = 0;
	}

	return $error;
}

sub revision_before($) {
	my ($revision) = @_;

	if ((($proto_version & REVISION_MASK) >> 8) < $revision) {
		$error = -5;
	} else {
		$error = 0;
	}

	return $error;
}

sub patch_before($) {
	my ($patch) = @_;

	if (($proto_version & PATCH_MASK) < $patch) {
		$error = -5;
	} else {
		$error = 0;
	}

	return $error;
}

sub version_before($) {
	my ($version) = @_;

	if ($proto_version < $version) {
		$error = -5;
	} else {
		$error = 0;
	}

	return $error;
}

sub vendor_not($) {
	my ($vendor) = @_;

	if ($mount_vendor == $vendor) {
		$error = 0;
	} else {
		$error = -5;
	}

	return $error;
}

sub vendor_is($) {
	my ($vendor) = @_;

	if ($mount_vendor == $vendor) {
		return 1;
	} else {
		return 0;
	}
}

=head1 TELESCOPE COMMUNICATION

=over 8

=item open_telescope_port(port_name)

Opens a communication port to the telescope by name (like "/dev/ttyUSB0") and
returns it to be used in other functions. If the port_name has "tcp://" prefix
the rest of the string is interpreted as an IP address and port where to connect to
(like "tcp://localhost:9999"). In case of error undef is returned.

NOTE: To be used with TCP you need to run nexbridge on the remote computer.

=cut
sub open_telescope_port($) {
	my ($portname) = @_;

	my $port;

	if ($portname =~ /^tcp:\/\//) {
		$portname =~ s/^tcp:\/\///;
		$is_tcp=1;
	} else {
		$is_tcp=0;
	}

	if ($is_tcp) {
		my $port = new IO::Socket::INET(
			PeerHost => $portname,
			Proto => 'tcp'
		) or return undef;
		return $port;
	}

	if ($^O eq "MSWin32") {
		$port = new Win32::SerialPort($portname);
	} else {
		$port = new Device::SerialPort($portname);
	}
	if (! defined $port) {return undef;}
	#$port->debug(1);
	$port->baudrate(9600); 
	$port->parity("none"); 
	$port->databits(8); 
	$port->stopbits(1); 
	$port->datatype('raw');    
	$port->write_settings;
	$port->read_char_time(0);     # don't wait for each character
	$port->read_const_time(TIMEOUT*1000);

	$mount_vendor = guess_mount_vendor($port);
	if (! defined $mount_vendor) {
		$port->close();
		return undef;
	}

	return $port;
}


# For internal library use only!
sub read_byte($) {
	my ($port) = @_;

	my ($byte, $count, $char);

	if ($is_tcp == 0) {
		($count,$char)=$port->read(1);
	} else {
		eval {
			local $SIG{ALRM} = sub { die "TimeOut" };
			alarm TIMEOUT;
			$count=$port->read($char,1);
			alarm 0;
		};
		if ($@ and $@ !~ /TimeOut/) {
			return undef;
		}
	}
	return ($count,$char);
}


=item read_telescope(port, len)
=item read_telescope(port, len , vl)

Reads data from the telescope. On error or in case less than len bytes are read undef is returned.
If "vl" is true the function will return success if "#" is read before the len bytes are read.

=cut
sub read_telescope {
	my ($port,$len,$vl) = @_;
	my $response;
	my $char;
	my $count;
	my $total=0;
	do {
		($count,$char)=read_byte($port);
		if ($count == 0) { return undef; }
		$total += $count;
		$response .= $char;
		if (($vl) and ($char eq "#")) {
			return $response;
		}
	} while ($total < $len);

	# if the last byte is not '#', this means that the device did
	# not respond and the next byte should be '#' (hopefully)
	if ($char ne "#") {
		($count,$char)=read_byte($port);
		return undef;
	}
	return $response;
}

=item write_telescope(port, data)

Writes data to the telescope and the result of write is returned.

=cut
sub write_telescope($$) {
	my ($port, $data) = @_;

	return $port->write($data);
}

=item close_telescope_port(port)

Closes the communication port to the telescope.

=cut

sub close_telescope_port($) {
	my ($port) = @_;

	$port->close;
  	undef $port;   
}

=item enforce_protocol_version(port, ver)

Enforce protocol minimal version checking. If a specific command is not supported by the firmware version given
in ver, the corresponding tc_*() call will fail as unsupported and return undef (in this case $NexStarCtl::error
will be set to -5). If version is VER_AUX, version enforcement
is disabled and all commands are enabled but some may fail, because they may not be supported by the current hand controller
firmware. To avoid this use VER_AUTO (or omit it) to set the version to the value reported by the currently connected hand
controller. By default protocol version enforcement is disabled and the unsupported commands will either timeout
or return erratic results. Because of this, calling enforce_protocol_version() with VER_AUTO or no ver parameter right after
open_telescope_port() is highly recommended. The predefined versions are: VER_1_2, VER_1_6, VER_2_2, VER_2_3, VER_3_1, VER_4_10 and VER_4_37_8.

NOTE: The non-documented (AUX) commands are available only when the enforcement is disabled.

=cut

sub enforce_protocol_version {
	my ($port, $ver) = @_;

	if ((defined $ver) and ($ver != 0)) {
		$proto_version = $ver;
		return 1;
	}
	my ($major,$minor,$subminor) = tc_get_version($port);
	if (!defined $major) { return undef; }
	$proto_version = ($major << 16) + ($minor << 8) + $subminor;
	return 1;
}

=item guess_mount_vendor(port)

This function guesses the manufacturer of the mount by a slight difference in the protocol. The firmware version command returns 2 bytes for Celestron mounts and 6 bytes for SkyWatcher mounts (since version 4.37.8). On success the guessed value is returned (VNDR_CELESTRON or VNDR_SKYWATCHER). On error undef is returned.

NOTE: SkyWather mounts with firmware before 4.37.8 will be threated as Celestron in this case enforce_vendor_protocol() can be used.
=cut

sub guess_mount_vendor {
	my ($port) = @_;
	return undef if version_before(VER_1_2);

	$port->write("V");
	my $response = read_telescope($port, 7, 1);

	return undef unless (defined $response);

	if (length($response) == 3) {
		return VNDR_CELESTRON;
	} elsif (length($response) == 7) {
		return VNDR_SKYWATCHER;
	} else {
		return undef;
	}
}

=item enforce_vendor_protocol(vendor)

This function enforces protocol of the specified vendor to be used overriding the guessed one.
Valid vendor IDs are VNDR_CELESTRON and VNDR_SKYWATCHER. This way the commands not supported
by the vendor version of the protocol will fail and $NexStarCtl::error will be set to -5.
On success the vendor ID is returned otherwise it returns undef.

=cut

sub enforce_vendor_protocol($) {
	my ($vendor) = @_;

	if (!(VNDR_ALL_SUPPORTED & $vendor)) {
		return undef;
	}

	$mount_vendor = $vendor;
}

#
#  Telescope Commands
#

=back

=head1 TELESCOPE COMMANDS

=over 8

=item tc_check_align(port)

If the telescope is aligned 1 is returned else 0 is returned. If no response received,
undef is returned.

=cut
sub tc_check_align($) {
	my ($port) = @_;

	return undef if version_before(VER_1_2);

	$port->write("J");
	my $response = read_telescope($port,2);
	if (defined $response) {
		return ord(substr($response, 0, 1));
	} else {
		return undef;
	}
}

=item tc_get_orientation(port)

Get the telescope orientation. "E" or "W" is returned for East and West respectively. If no response received,
undef is returned.

=cut
sub tc_get_orientation($) {
	my ($port) = @_;

	return undef if vendor_not(VNDR_SKYWATCHER);
	return undef if release_before(3);
	return undef if revision_before(37);

	$port->write("p");
	my $response = read_telescope($port,2);
	if (defined $response) {
		return substr($response, 0, 1);
	} else {
		return undef;
	}
}

=item tc_goto_rade(port, ra, de)

=item tc_goto_rade_p(port, ra, de)

Slew the telescope to RA/DEC coordinates ra, de (in decimal degrees). 
Function tc_goto_rade_p uses precise GOTO.
If RA is not in [0;360] function returns -1. If DEC is not in [-90;90] -2 is returned.
If no response received, undef is returned.

=cut
sub tc_goto_rade {
	my ($port, $ra, $de, $precise) = @_;
	if (($ra < 0) or ($ra > 360)) {
		return -1;
	}
	if (($de < -90) or ($de > 90)) {
		return -2;
	}
	my $nex;
	if((defined $precise) and ($precise =! 0)) {
		return undef if version_before(VER_1_6);
		$nex=dd2pnex($ra, $de);
		$port->write("r".$nex);
	} else {
		return undef if version_before(VER_1_2);
		$nex=dd2nex($ra, $de);
		$port->write("R".$nex);
	}
	my $response = read_telescope($port,1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

sub tc_goto_rade_p {
	return tc_goto_rade(@_, 1); 
}

=item tc_goto_azalt(port, az, alt)

=item tc_goto_azalt_p(port, az, alt)

Slew the telescope to AZ/ALT coordinates az, alt (in decimal degrees). Function tc_goto_azalt_p uses precise GOTO.
If AZ is not in [0;360] function returns -1. If ALT is not in [-90;90] -2 is returned.
If no response received, undef is returned.

=cut
sub tc_goto_azalt {
	my ($port, $az, $alt, $precise) = @_;
	if (($az < 0) or ($az > 360)) {
		return -1;
	}
	if (($alt < -90) or ($alt > 90)) {
		return -2;
	}
	my $nex;
	if((defined $precise) and ($precise =! 0)) {
		return undef if version_before(VER_2_2);
		$nex=dd2pnex($az, $alt);
		$port->write("b".$nex);
	} else {
		return undef if version_before(VER_1_2);
		$nex=dd2nex($az, $alt);
		$port->write("B".$nex);
	}
	my $response = read_telescope($port,1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}	
}

sub tc_goto_azalt_p {
	return tc_goto_azalt(@_, 1);
}

=item tc_get_rade(port)

=item tc_get_rade_p(port)

Returns the the current telescope RA/DEC coordinates ra, de (in decimal degrees). Function 
tc_get_rade_p uses precise GET. If no response received, undef is returned.

=cut
sub tc_get_rade {
	my ($port, $precise) = @_;
	
	my $ra;
	my $de;
	
	if((defined $precise) and ($precise =! 0)) {
		return undef if version_before(VER_1_6);
		$port->write("e");
		my $response = read_telescope($port, 18);
		if (! defined $response) {
			return undef;
		} 
		($ra,$de) = pnex2dd($response);
	} else {
		return undef if version_before(VER_1_2);
		$port->write("E");
		my $response = read_telescope($port, 10);
		if (! defined $response) {
			return undef;
		} 
		($ra,$de) = nex2dd($response);
	}
	
	return ($ra, $de);
}

sub tc_get_rade_p {
	return tc_get_rade(@_, 1); 
}

=item tc_get_azalt(port)

=item tc_get_azalt_p(port)

Returns the the currents telescope AZ/ALT coordinates az, alt (in decimal degrees). Function 
tc_get_azalt_p uses precise GET. If no response received, undef is returned.

=cut
sub tc_get_azalt {
	my ($port, $precise) = @_;
	
	my $az;
	my $alt;
	
	if((defined $precise) and ($precise =! 0)) {
		return undef if version_before(VER_2_2);
		$port->write("z");
		my $response = read_telescope($port, 18);
		if (! defined $response) {
			return undef;
		} 
		($az,$alt) = pnex2dd($response);
	} else {
		return undef if version_before(VER_1_2);
		$port->write("Z");
		my $response = read_telescope($port, 10);
		if (! defined $response) {
			return undef;
		} 
		($az,$alt) = nex2dd($response);
	}
	
	return ($az, $alt);
}

sub tc_get_azalt_p {
	return tc_get_azalt(@_, 1); 
}

=item tc_sync_rade(port, ra, de)

=item tc_sync_rade_p(port, ra, de)

Syncs the telescope to RA/DEC coordinates ra, de (in decimal degrees). Function tc_sync_rade_p uses precise sync.
If RA is not in [0;360] function returns -1. If DEC is not in [-90;90] -2 is returned.
If no response received, undef is returned.

=cut
sub tc_sync_rade {
	my ($port, $ra, $de, $precise) = @_;

	if(vendor_is(VNDR_SKYWATCHER)) {
		return undef if release_before(3);
		return undef if revision_before(37);
	} else {
		return undef if version_before(VER_4_10);
	}

	if (($ra < 0) or ($ra > 360)) {
		return -1;
	}
	if (($de < -90) or ($de > 90)) {
		return -2;
	}
	my $nex;
	if((defined $precise) and ($precise =! 0)) {
		$nex=dd2pnex($ra, $de);
		$port->write("s".$nex);
	} else {
		$nex=dd2nex($ra, $de);
		$port->write("S".$nex);
	}
	my $response = read_telescope($port, 1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

sub tc_sync_rade_p {
	return tc_sync_rade(@_, 1); 
}

=item tc_goto_in_progress(port)

Returns 1 if GOTO is in progress else 0 is returned. If no response received, undef is returned.

=cut
sub tc_goto_in_progress($) {
	my ($port) = @_;

	return undef if version_before(VER_1_2);

	$port->write("L");
	my $response = read_telescope($port, 2);
	if (defined $response) {
		return substr($response, 0, 1);
	} else {
		return undef;
	}
}

=item tc_goto_cancel(port)

Cancels the GOTO operation. On success 1 is returned. If no response received, undef is returned.

=cut
sub tc_goto_cancel($) {
	my ($port) = @_;

	return undef if version_before(VER_1_2);
		        
	$port->write("M");
	my $response = read_telescope($port, 1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_echo(port, char)

Checks the communication with the telescope. This function sends char to the telescope and 
returns the echo received. If no response received, undef is returned.

=cut
sub tc_echo($$) {
	my ($port, $char) = @_;

	return undef if version_before(VER_1_2);

	$port->write("K".substr($char, 0, 1));
	my $response = read_telescope($port, 2);
	if (defined $response) {
		return substr($response, 0, 1);
	} else {
		return undef;
	}
}

=item tc_get_model(port)

This function returns the mount model as a number. See CELESTRON documentation.
If no response received, undef is returned.

=cut
sub tc_get_model($) {
	my ($port) = @_;

	return undef if version_before(VER_2_2);

	$port->write("m");
	my $response = read_telescope($port, 2);
	if (defined $response) {
		return ord(substr($response, 0, 1));
	} else {
		return undef;
	}
}

=item tc_get_version(port)

This function returns the mount version as a strng or as major and minor numbers in array context  See CELESTRON documentation.
If no response received, undef is returned.

=cut
sub tc_get_version($) {
	my ($port) = @_;

	return undef if version_before(VER_1_2);

	$port->write("V");
	my $response = read_telescope($port, 7, 1);
	if (defined $response) {
		if (length($response) == 3) {
			return wantarray ? (ord(substr($response, 0, 1)),ord(substr($response, 1, 1)))
				         : ord(substr($response, 0, 1)).".".ord(substr($response, 1, 1));
		} elsif (length($response) == 7) {
			return wantarray ? (hex(substr($response, 0, 2)),hex(substr($response, 2, 2)),hex(substr($response, 4, 2)))
				         : hex(substr($response, 0, 2)).".".hex(substr($response, 2, 2)).".".hex(substr($response, 4, 2));
		}
	}

	return undef;
}


=item tc_get_location(port)

This function returns the stored location coordinates lon, lat in decimal degrees. 
Negative longitude is WEST. Negative latitude is SOUTH.
If no response received, undef is returned.

=item tc_get_location_str(port)

This function returns the stored location coordinates lon and lat as strings.
If no response received, undef is returned.

=cut
sub tc_get_location {
	my ($port,$str) = @_;

	return undef if version_before(VER_2_3);

	$port->write("w");
	my $response = read_telescope($port, 9);
	if (! defined $response) {
		return undef;
	}
	
	my $latd=ord(substr($response, 0, 1));
	my $latm=ord(substr($response, 1, 1));
	my $lats=ord(substr($response, 2, 1));
	my $lato=ord(substr($response, 3, 1));
	my $lond=ord(substr($response, 4, 1));
	my $lonm=ord(substr($response, 5, 1));
	my $lons=ord(substr($response, 6, 1));
	my $lono=ord(substr($response, 7, 1));

	my $lon;
	my $lat;
	if((defined $str) and ($str =! 0)) {
		$lat=sprintf("%d %02d'%02d\"N",$latd,$latm,$lats);
		$lon=sprintf("%d %02d'%02d\"E",$lond,$lonm,$lons);
		if ($lato) {
			$lat =~ s/N$/S/;
		}
		if ($lono) {
			$lon =~ s/E$/W/;
		}
	} else {
		$lat=($latd + $latm/60.0 + $lats/3600.0);
		$lon=($lond + $lonm/60.0 + $lons/3600.0);
		if ($lato) {
			$lat *= -1;
		}
		if ($lono) {
			$lon *= -1;
		}
	}
	return ($lon, $lat);
}

sub tc_get_location_str {
	return tc_get_location(@_, 1);
}

=item tc_set_location(port,lon,lat)

This function sets the location coordinates lon, lat in decimal degrees. 
Negative longitude is WEST. Negative latitude is SOUTH.
If the coordinates are invalid -1 is returned.
If no response received, undef is returned.

=cut
sub tc_set_location {
	my ($port,$lon,$lat) = @_;
	my $issouth = 0;
	my $iswest = 0;

	return undef if version_before(VER_2_3);
	
	if ($lon < 0) {
		$lon *= -1;
		$iswest = 1;
	}
	if ($lat < 0) {
		$lat *= -1;
		$issouth = 1;
	}

	if (($lat > 90) or ($lon > 180)) {
		return -1;
	}
	
	my ($lond,$lonm,$lons) = d2dms2($lon);
	my ($latd,$latm,$lats) = d2dms2($lat);

	$port->write("W");
	$port->write(chr($latd));
	$port->write(chr($latm));
	$port->write(chr($lats));
	$port->write(chr($issouth));
	$port->write(chr($lond));
	$port->write(chr($lonm));
	$port->write(chr($lons));
	$port->write(chr($iswest));

	my $response = read_telescope($port, 1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_get_time(port)

This function returns the stored time (in Unix time format), timezone (in hours) and daylight saving time(0|1).
If no response received, undef is returned.

=item tc_get_time_str(port)

This function returns the stored date, time (as strings), timezone (in hours) and daylight saving time(0|1).
If no response received, undef is returned.

=cut

sub tc_get_time {
	my ($port,$str) = @_;

	return undef if version_before(VER_2_3);

	$port->write("h");
	my $response = read_telescope($port, 9);
	if (! defined $response) {
		return undef;
	}
	
	my $h=ord(substr($response, 0, 1));
	my $m=ord(substr($response, 1, 1));
	my $s=ord(substr($response, 2, 1));
	my $mon=ord(substr($response, 3, 1));
	my $day=ord(substr($response, 4, 1));
	my $year=ord(substr($response, 5, 1))+2000;
	my $tz=ord(substr($response, 6, 1));
	$tz -= 256 if ($tz > 12);
	my $dst=ord(substr($response, 7, 1));
	
	if((defined $str) and ($str =! 0)) {
		my $time=sprintf("%2d:%02d:%02d",$h,$m,$s);
		my $date=sprintf("%02d-%02d-%04d",$day,$mon,$year);
		return ($date,$time, $tz, $dst);
	} else {
		my $time = timelocal($s,$m,$h,$day,$mon-1,$year);
		return ($time, $tz, $dst);
	}
}

sub tc_get_time_str {
	return tc_get_time(@_, 1);
}

=item tc_set_time(port, time, timezone, daylightsaving)

This function sets the time (in Unix time format), timezone (in hours) and daylight saving time(0|1).
On success 1 is returned.
If no response received, undef is returned. If the mount is known to have RTC
(currently only CGE and AdvancedVX) and NexStarCtl::use_rtc is defined and != 0 (default is 0), the date/time is
set to the RTC too.

NOTE: Do not set NexStarCtl::use_rtc if the mount is SkyWatcher otherwise tc_set_time() may fail.

=cut
sub tc_set_time {
	my ($port, $time, $tz, $dst) = @_;

	return undef if version_before(VER_2_3);

	my $timezone = $tz;
	$tz += 256 if ($tz < 0);

	if ((defined $dst) and ($dst != 0)) {
		$dst=1;
	} else {
		$dst=0;	
	}

	my ($s,$m,$h,$day,$mon,$year,$wday,$yday,$isdst) = localtime($time);

	$port->write("H");
	$port->write(chr($h));
	$port->write(chr($m));
	$port->write(chr($s));
	$port->write(chr($mon+1));
	$port->write(chr($day));
	# $year is actual_year-1900
	# here is required actual_year-2000
	# so we need $year-100
	$port->write(chr($year-100));
	$port->write(chr($tz));
	$port->write(chr($dst));

	my $response = read_telescope($port, 1);
	if (! defined $response) {
		return undef;
	}

	# return success if the RTC is not used
	if (($use_rtc == 0) or ($use_rtc == undef)) {
		return 1;
	}

	my $model = tc_get_model($port);
	# If the mount has RTC set date/time to RTC too
	# I only know CGE(5) and AdvancedVX(20) to have RTC
	if (($model == 5) or ($model == 20)) {
		# RTC expects UT, convert localtime to UT
		my ($s,$m,$h,$day,$mon,$year,$wday,$yday,$isdst) = localtime($time - (($timezone + $dst) * 3600));

		# Set year
		my $response = tc_pass_through_cmd($port, 3, 178, 132,
		                                   int(($year + 1900) / 256),
		                                   int(($year + 1900) % 256), 0, 0);
		if (! defined $response) {
			return undef;
		}

		# Set month and day
		my $response = tc_pass_through_cmd($port, 3, 178, 131, $mon+1, $day, 0, 0);
		if (! defined $response) {
			return undef;
		}

		# Set time
		my $response = tc_pass_through_cmd($port, 4, 178, 179, $h, $m, $s, 0);
		if (! defined $response) {
			return undef;
		}
	}
	return 1;
}

=item tc_get_tracking_mode(port)

Reads the tracking mode of the mount and returns one of the folowing:
TC_TRACK_OFF, TC_TRACK_ALT_AZ, TC_TRACK_EQ_NORTH (Celestron only), TC_TRACK_EQ_SOUTH (Celestron only),
TC_TRACK_EQ (SkyWatcher only) and TC_TRACK_EQ_PEC (Sky-Watcher only).
If no response received, undef is returned.

=cut
sub tc_get_tracking_mode($) {
	my ($port) = @_;
	my $mode;

	return undef if version_before(VER_2_3);

	$port->write("t");
	my $response = read_telescope($port, 2);
	if (defined $response) {
		$mode = ord(substr($response, 0, 1));
	} else {
		return undef;
	}

	# Sky-Watcher mount
	if(vendor_is(VNDR_SKYWATCHER)) {
		if ($mode == SW_TC_TRACK_OFF) {
			return TC_TRACK_OFF;

		} elsif ($mode == SW_TC_TRACK_ALT_AZ) {
			return TC_TRACK_ALT_AZ;

		} elsif ($mode == SW_TC_TRACK_EQ) {
			return TC_TRACK_EQ;

		} elsif ($mode == SW_TC_TRACK_EQ_PEC) {
			return TC_TRACK_EQ_PEC;
		}
	# Celestron mount
	} else {
		if ($mode == NX_TC_TRACK_OFF) {
			return TC_TRACK_OFF;

		} elsif ($mode == NX_TC_TRACK_ALT_AZ) {
			return TC_TRACK_ALT_AZ;

		} elsif ($mode == NX_TC_TRACK_EQ_NORTH) {
			return TC_TRACK_EQ_NORTH;

		} elsif ($mode == NX_TC_TRACK_EQ_SOUTH) {
			return TC_TRACK_EQ_SOUTH;
		}
	}
	return undef;
}

=item tc_set_tracking_mode(port, mode)

Sets the tracking mode of the mount to one of the folowing:
TC_TRACK_OFF, TC_TRACK_ALT_AZ, TC_TRACK_EQ_NORTH, TC_TRACK_EQ_SOUTH, TC_TRACK_EQ and TC_TRACK_EQ_PEC.
For Sky-Watcher TC_TRACK_EQ_NORTH, TC_TRACK_EQ_SOUTH and TC_TRACK_EQ do the same thing. For Celestron
TC_TRACK_EQ is interpreted as TC_TRACK_EQ_NORTH or TC_TRACK_EQ_SOUTH depending on the geographic latitude
of the location (Northern or Southern hemisphere). If the mode is not one of the listed -1 is returned.
If no response received, undef is returned.

=cut
sub tc_set_tracking_mode($$) {
	my ($port,$mode) = @_;
	my $_mode;

	return undef if version_before(VER_1_6);

	# Sky-Watcher mount
	if(vendor_is(VNDR_SKYWATCHER)) {
		if ($mode == TC_TRACK_OFF) {
			$_mode = TC_TRACK_OFF;

		} elsif ($mode == TC_TRACK_ALT_AZ) {
			$_mode = SW_TC_TRACK_ALT_AZ;

		} elsif (($mode == TC_TRACK_EQ) or
				($mode == TC_TRACK_EQ_NORTH) or
				($mode == TC_TRACK_EQ_SOUTH)) {
			$_mode = SW_TC_TRACK_EQ;

		} elsif ($mode == TC_TRACK_EQ_PEC) {
			$_mode = SW_TC_TRACK_EQ_PEC;

		} else {
			return -1;
		}

	# Celestron mount
	} else {
		if ($mode == TC_TRACK_OFF) {
			$_mode = NX_TC_TRACK_OFF;

		} elsif ($mode == TC_TRACK_ALT_AZ) {
			$_mode = NX_TC_TRACK_ALT_AZ;

		} elsif ($mode == TC_TRACK_EQ_NORTH) {
			$_mode = NX_TC_TRACK_EQ_NORTH;

		} elsif ($mode == TC_TRACK_EQ_SOUTH) {
			$_mode = NX_TC_TRACK_EQ_SOUTH;

		} elsif ($mode == TC_TRACK_EQ) {
			my (undef, $lat) = tc_get_location($port);
			if (!defined $lat) {
				return -1;
			}
			if ($lat < 0) {
				$_mode = NX_TC_TRACK_EQ_SOUTH;
			} else {
				$_mode = NX_TC_TRACK_EQ_NORTH;
			}

		} elsif ($mode == TC_TRACK_EQ_PEC) {
			# unsupported on Celestron
			$error = -5;
			return undef;

		} else {
			return -1;
		}
	}

	$port->write("T");
	$port->write(chr($_mode));
	my $response = read_telescope($port, 1);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_slew_fixed(port, axis, direction, rate)

Move the telescope the telescope around a specified axis in a given direction with fixed rate.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT. Direction can accept values 
TC_DIR_POSITIVE and TC_DIR_NEGATIVE. Rate is from 0 to 9. Where 0 stops slewing and 9 is 
the fastest speed.

On success 1 is returned. If rate is out of range -1 is returned. 
If no response received, undef is returned.

=cut
sub tc_slew_fixed {
	my ($port,$axis,$direction,$rate) = @_;

	if(vendor_is(VNDR_SKYWATCHER)) {
		return undef if release_before(3);
		return undef if revision_before(1);
	} else {
		return undef if version_before(VER_1_6);
	}
	
	if ($axis>0) { 
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	if ($direction > 0) {
		$direction = _TC_DIR_POSITIVE + 30;
	} else {
		$direction = _TC_DIR_NEGATIVE + 30;
	}
	
	if (($rate < 0) or ($rate > 9)) {
		return -1;
	}
	$rate = int($rate);

	my $response = tc_pass_through_cmd($port, 2, $axis, $direction, $rate, 0, 0, 0);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_slew_variable(port, axis, direction, rate)

Move the telescope the telescope around a specified axis in a given direction with specified rate.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT. Direction can accept values 
TC_DIR_POSITIVE and TC_DIR_NEGATIVE. Rate is the speed in arcsec/sec. For example 3600 
represents 1degree/sec. 

On success 1 is returned. If no response received, undef is returned.

=cut
sub tc_slew_variable {
	my ($port,$axis,$direction,$rate) = @_;

	if(vendor_is(VNDR_SKYWATCHER)) {
		return undef if release_before(3);
		return undef if revision_before(1);
	} else {
		return undef if version_before(VER_1_6);
	}

	if ($axis>0) { 
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	if ($direction > 0) {
		$direction = _TC_DIR_POSITIVE;
	} else {
		$direction = _TC_DIR_NEGATIVE;
	}
	
	$rate = int(4*$rate);
	my $rateH = int($rate / 256);
	my $rateL = $rate % 256;
	#print "RATEf : $rateH $rateL\n";

	my $response = tc_pass_through_cmd($port, 3, $axis, $direction, $rateH, $rateL, 0, 0);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item get_model_name(model_id)

Return the name of the mount by the id from tc_get_model().
If the mount is not known undef is returned.

=cut

sub get_model_name($) {
	my ($model_id) = @_;
	return $mounts{$mount_vendor}{$model_id};
}

=back

=head1 AUX COMMANDS

The following commands are not officially documented by Celestron. Please note that these
commands are reverse engineered and may not work exactly as expected.

=over 8

=item tc_get_autoguide_rate(port, axis)

Get autoguide rate for the given axis in percents of the sidereal rate.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT.

On success current value of autoguide rate is returned in the range [0-99].
If no response received, undef is returned.
=cut
sub tc_get_autoguide_rate($$) {
	my ($port,$axis) = @_;

	return undef if version_before(VER_AUX);

	if ($axis > 0) {
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	# Get autoguide rate (0x47)
	my $response = tc_pass_through_cmd($port, 1, $axis, 0x47, 0, 0, 0, 1);
	if (defined $response) {
		my $rate = ord(substr($response, 0, 1));
		return int(100 * $rate / 256);
	} else {
		return undef;
	}
}

=item tc_set_autoguide_rate(port, axis, rate)

Set autoguide rate for the given axis in percents of the sidereal rate.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT.
Rate must be in the range [0-99].

On success 1 is returned. If rate is out of range -1 is returned.
If no response received, undef is returned.
=cut
sub tc_set_autoguide_rate($$$) {
	my ($port,$axis,$rate) = @_;

	return undef if version_before(VER_AUX);

	if ($axis > 0) {
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	# $rate should be [0%-99%]
	my $rate = int($rate);
	if (($rate < 0) or ($rate > 99)) {
		return -1;
	}

	# This is wired, but is done to match as good as
	# possible the values given by the HC
	my$rrate;
	if ($rate == 0) {
		$rrate = 0;
	} elsif ($rate == 99) {
		$rrate = 255;
	} else {
		$rrate = int((256 * $rate / 100) + 1);
	}

	# Set autoguide rate (0x46)
	my $response = tc_pass_through_cmd($port, 2, $axis, 0x46, $rrate, 0, 0, 0);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_get_backlash(port, axis, direction)

Get anti-backlash values for the specified axis in a given direction.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT. Direction
can accept values TC_DIR_POSITIVE and TC_DIR_NEGATIVE.

On success current value of backlash is returned in the range [0-99].
If no response received, undef is returned.
=cut
sub tc_get_backlash($$$) {
	my ($port,$axis,$direction) = @_;

	return undef if vendor_not(VNDR_CELESTRON);
	return undef if version_before(VER_AUX);

	if ($axis > 0) {
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	if ($direction > 0) {
		$direction = 0x40; # Get positive backlash
	} else {
		$direction = 0x41; # Get negative backlash
	}

	my $response =  tc_pass_through_cmd($port, 1, $axis, $direction, 0, 0, 0, 1);
	if (defined $response) {
		return ord(substr($response, 0, 1));
	} else {
		return undef;
	}
}

=item tc_set_backlash(port, axis, direction, backlash)

Set anti-backlash values for the specified axis in a given direction.

Accepted values for axis are TC_AXIS_RA_AZM and TC_AXIS_DE_ALT. Direction can accept
values TC_DIR_POSITIVE and TC_DIR_NEGATIVE. Backlash must be in the range [0-99].

On success 1 is returned. If backlash is out of range -1 is returned.
If no response received, undef is returned.
=cut
sub tc_set_backlash($$$$) {
	my ($port,$axis,$direction,$backlash) = @_;

	return undef if vendor_not(VNDR_CELESTRON);
	return undef if version_before(VER_AUX);

	if ($axis > 0) {
		$axis = _TC_AXIS_RA_AZM;
	} else {
		$axis = _TC_AXIS_DE_ALT;
	}

	if ($direction > 0) {
		$direction = 0x10; # Set positive backlash
	} else {
		$direction = 0x11; # Set negative backlash
	}

	my $backlash = int($backlash);
	if (($backlash < 0) or ($backlash > 99)) {
		return -1;
	}

	my $response = tc_pass_through_cmd($port, 2, $axis, $direction, $backlash, 0, 0, 0);
	if (defined $response) {
		return 1;
	} else {
		return undef;
	}
}

=item tc_pass_through_cmd(port, msg_len, dest_id, cmd_id, data1, data2, data3, res_len)

Send a pass through command to a specific device. This function is meant for an internal
library use and should not be used, unless you know exactly what you are doing.
Calling this function with wrong parameters can be dangerous and can break the telescope!

=cut
sub tc_pass_through_cmd($$$$$$$$) {
	my ($port, $msg_len, $dest_id, $cmd_id, $data1, $data2, $data3, $res_len) = @_;

	$port->write("P");
	$port->write(chr($msg_len));
	$port->write(chr($dest_id));
	$port->write(chr($cmd_id));
	$port->write(chr($data1));
	$port->write(chr($data2));
	$port->write(chr($data3));
	$port->write(chr($res_len));

	# we should read $res_len + 1 byes to accomodate '#' at the end
	return read_telescope($port, $res_len + 1);
}

=back

=head1 UTILITY FUNCTIONS

=over 8

=item notnum(n)

If "n" is a real number returns 0 else it returns 1.

=cut
sub notnum($)
{	my ($num) = @_;
	if ($num=~ /^[-+]?\d+\.?\d*$/) {return 0;}
	else {return 1;}
} 


=item precess(ra0, dec0, equinox0, equinox1)

Precesses coordinates ra0 and dec0 from equinox0 to equinox1 and returns the calculated ra1 and dec1. 
Where ra and dec should be in decimal degrees and equinox should be in years (and fraction of the year).

=cut
sub precess(@)
{
	my ($ra0,$de0,$eq0,$eq1)=@_;
	my ($cosd,$ra,$dec,
			$A,$B,$C,
			$x0,$y0,$z0,
			$x1,$y1,$z1,
			$ST,$T,$sec2rad);
	my @rot;

	my ($sinA,$sinB,$sinC,$cosA,$cosB,$cosC,$sind);

	my ($ra1,$de1);

	$ra = $ra0*DEG2RAD;
	$dec = $de0*DEG2RAD;

	$cosd = cos($dec);

	$x0=$cosd*cos($ra);
	$y0=$cosd*sin($ra);
	$z0=sin($dec);

	$ST=($eq0-2000.0)*0.001;
	$T=($eq1-$eq0)*0.001;

	$sec2rad=(DEG2RAD)/3600.0;
	$A=$sec2rad*$T*(23062.181+$ST*(139.656+0.0139*$ST)+$T*
                                (30.188-0.344*$ST+17.998*$T));
	$B=$sec2rad*$T*$T*(79.280+0.410*$ST+0.205*$T)+$A;
	$C=$sec2rad*$T*(20043.109-$ST*(85.33+0.217*$ST)+$T*
                                (-42.665-0.217*$ST-41.833*$T));

	$sinA=sin($A);  $sinB=sin($B);  $sinC=sin($C);
	$cosA=cos($A);  $cosB=cos($B);  $cosC=cos($C);

	$rot[0][0]=$cosA*$cosB*$cosC-$sinA*$sinB;
	$rot[0][1]=(-1)*$sinA*$cosB*$cosC-$cosA*$sinB;
	$rot[0][2]=(-1)*$sinC*$cosB;

	$rot[1][0]=$cosA*$cosC*$sinB+$sinA*$cosB;
	$rot[1][1]=(-1)*$sinA*$cosC*$sinB+$cosA*$cosB;
	$rot[1][2]=(-1)*$sinB*$sinC;

	$rot[2][0]=$cosA*$sinC;
	$rot[2][1]=(-1)*$sinA*$sinC;
	$rot[2][2]=$cosC;
	
	$x1=$rot[0][0]*$x0+$rot[0][1]*$y0+$rot[0][2]*$z0;
	$y1=$rot[1][0]*$x0+$rot[1][1]*$y0+$rot[1][2]*$z0;
	$z1=$rot[2][0]*$x0+$rot[2][1]*$y0+$rot[2][2]*$z0;

	if ($x1==0) {
		if ($y1 > 0) { $ra1=90.0;}
		else { $ra1=270.0;}
	}
	else {$ra1=atan2($y1,$x1)*RAD2DEG;}
	if($ra1<0) { $ra1+=360;}

	$de1=RAD2DEG*atan2($z1,sqrt(1-$z1*$z1));

	return ($ra1,$de1);
}

########################################################
######## Mathematics 
########################################################

=item round(n)

Returns the rounded number n.

=cut
sub round($){
	my($num)=@_;
	my ($retval);
	if (($num - floor($num)) < 0.5) { $retval = floor($num); }
	else { $retval = floor($num) + 1; }
	return $retval;
}


=item d2hms(deg)

Converts deg (in decimal degrees) to string in hours, minutes and seconds notion (like "12h 10m 44s").

=cut
sub d2hms($)   # Looks OK! :)
{
	my ($ra)=@_;

	$ra=$ra/15;
	my $hr=int($ra*3600+0.5);
	my $hour=int($hr/3600);
	my $f=int($hr%3600);
	my $min=int($f/60);
	my $sec=int($f%60);
	my $ra_str = sprintf "%02dh %02dm %02ds", $hour,$min,$sec; 
	return $ra_str;
}

=item d2dms(deg)

Converts deg (in decimal degrees) to string in degrees, minutes and seconds notion 
(like "33:20:44").

=cut
sub d2dms($)  # Looks OK! :)
{
	my ($ang)=@_;
	if ($ang >= 0) {
		my $a=int($ang*3600+0.5);
		my $deg=int($a/3600);
		my $f=int($a%3600);
		my $min=int($f/60);
		my $sec=int($f%60);
		my $ang_str=sprintf "%02d:%02d:%02d",$deg,$min,$sec;
		return $ang_str;
	} else {
		$ang*=-1;
		my $a=int($ang*3600+0.5);
		my $deg=int($a/3600);
		my $f=int($a%3600);
		my $min=int($f/60);
		my $sec=int($f%60);
		my $ang_str=sprintf "-%02d:%02d:%02d",$deg,$min,$sec;
		return $ang_str;
	}
}
	
sub d2dms2($) {
	my ($ang)=@_;
	if ($ang >= 0) {
		my $a=int($ang*3600+0.5);
		my $deg=int($a/3600);
		my $f=int($a%3600);
		my $min=int($f/60);
		my $sec=int($f%60);
		return ($deg,$min,$sec);
	} else {
		$ang*=-1;
		my $a=int($ang*3600+0.5);
		my $deg=int($a/3600);
		my $f=int($a%3600);
		my $min=int($f/60);
		my $sec=int($f%60);
		return (-1*$deg,$min,$sec);
	}
}

=item d2dms(deg)

converts deg (in decimal degrees) to string in degrees and minutes notion (like "33:20").

=cut
sub d2dm($) 
{
	my ($ang)=@_;
	my $a=int($ang*3600+0.5);
	my $deg=int($a/3600);
	my $f=int($a%3600);
	my $min=int($f/60);
	my $ang_str=sprintf "%02d:%02d",$deg,$min;
	return $ang_str;
}

=item dms2d(string)

converts string of the format "dd:mm:ss" to decimal degrees. If the string format 
is invalid format, undef is returned.

=cut
sub dms2d($)
{
	my ($angle)=@_;
	
	my (@dms)=split(/:/,$angle);
	if (@dms>3 or $angle eq "") {
		return undef;
	}
	
	if (!($dms[0]=~ /^[+-]?\d+$/)) {
		 return undef; 
	}
	if ($dms[1]<0 or $dms[1]>59 or $dms[1]=~/[\D]/) {
		return undef;
	} 
	if ($dms[2]<0 or $dms[2]>59 or $dms[2]=~/[\D]/) {
		return undef;
	}
	
	if ($dms[0]=~ /^-/) {
		return ($dms[0]-$dms[1]/60-$dms[2]/3600);
	} else {
		return ($dms[0]+$dms[1]/60+$dms[2]/3600);
	}
}

=item hms2d(string)

Converts string of the format "hh:mm:ss" to decimal degrees. If the string format 
is invalid format, undef is returned.

=cut
sub hms2d($)
{
	my ($hours)=@_;
	
	my (@hms)=split(/:/,$hours);
	if (@hms>3 or $hours eq "") {
		return undef;
	}
	
	if ($hms[0]<0 or $hms[0]>23 or $hms[0]=~/[\D]/) {
		return undef;
	}
	if ($hms[1]<0 or $hms[1]>59 or $hms[1]=~/[\D]/) {
		return undef;
	} 
	if ($hms[2]<0 or $hms[2]>59 or $hms[2]=~/[\D]/) {
		return undef;
	}
	
	return (($hms[0]+$hms[1]/60+$hms[2]/3600)*15);	
}

###############################################
#  NexStar coordinate conversion
###############################################

=item nex2dd(string)

Converts NexStar hexadecimal coordinate string (in fraction of a revolution) of 
the format "34AB,12CE" to two decimal degree coordinates.

=cut
sub nex2dd ($){
	my ($nexres) = @_;
	my $d1_factor = hex(substr($nexres, 0, 4)) / 65536;
	my $d2_factor = hex(substr($nexres, 5, 4)) / 65536;
	my $d1 = 360 * $d1_factor; 
	my $d2 = 360 * $d2_factor;

	# bring $d2 in [-90,+90] range
	# use 90.00001 to fix some float errors
	# that lead +90 to be converted to -270
	$d2 = $d2 + 360 if ($d2 < -90.0002);
	$d2 = $d2 - 360 if ($d2 > 90.0002);

	return($d1, $d2);
}

=item pnex2dd(string)

Converts precision NexStar hexadecimal coordinate string (in fraction of a revolution) 
of the format "12AB0500,40000500" to two decimal degree coordinates.

=cut
sub pnex2dd ($){
	my ($nexres) = @_;
	my $d1_factor = hex(substr($nexres, 0, 8)) / 0xffffffff;
	my $d2_factor = hex(substr($nexres, 9, 8)) / 0xffffffff;
	my $d1 = 360 * $d1_factor;
	my $d2 = 360 * $d2_factor;

	# bring $d2 in [-90,+90] range
	# use 90.00001 to fix some float errors
	# that lead +90 to be converted to -270
	$d2 = $d2 + 360 if ($d2 < -90.0002);
	$d2 = $d2 - 360 if ($d2 > 90.0002);

	return($d1, $d2);
}


=item dd2nex(deg1,deg2)

Converts coordinates deg1 and deg2 (in decimal degrees) to NexStar hexadecimal coordinate 
string (in fraction of a revolution) of the format "34AB,12CE".

=cut
sub dd2nex ($$) {
	my ($d1, $d2) = @_;

	# bring $d1,$d2 in the range [0-360]
	$d1 = $d1 - 360 * int($d1/360);
	$d2 = $d2 - 360 * int($d2/360);
	$d1 = $d1 + 360 if ($d1 < 0);
	$d2 = $d2 + 360 if ($d2 < 0);

	my $d2_factor = $d2 / 360;
	my $d1_factor = $d1 / 360;

	my $nex1 = int($d1_factor*65536);
	my $nex2 = int($d2_factor*65536);

	return sprintf("%04X,%04X", $nex1,$nex2);
}

=item dd2nex(deg1,deg2)

Converts coordinates deg1 and deg2 (in decimal degrees) to precise NexStar hexadecimal 
coordinate string (in fraction of a revolution) of the format "12AB0500,40000500".

=cut
sub dd2pnex ($$) {
	my ($d1, $d2) = @_;

	# bring $d1,$d2 in the range [0-360]
	$d1 = $d1 - 360 * int($d1/360);
	$d2 = $d2 - 360 * int($d2/360);
	$d1 = $d1 + 360 if ($d1 < 0);
	$d2 = $d2 + 360 if ($d2 < 0);

	my $d2_factor = $d2 / 360;
	my $d1_factor = $d1 / 360;

	my $nex1 = int($d1_factor*0xffffffff);
	my $nex2 = int($d2_factor*0xffffffff);

	return sprintf("%08X,%08X", $nex1,$nex2);
}

=back

=head1 SEE ALSO

For more information about the NexStar commands please refer to the original
protocol specification described here:
http://www.celestron.com/c3/images/files/downloads/1154108406_nexstarcommprot.pdf

The undocumented commands are described here:
http://www.paquettefamily.ca/nexstar/NexStar_AUX_Commands_10.pdf

=head1 AUTHOR

Rumen Bogdanovski, E<lt>rumen@skyarchive.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Rumen Bogdanovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
