#!/usr/bin/perl
###############################################################
# Celestron NexStar telescope control tool. Its primary purpose
# is to illustrate how NexStarCtl module can be used, but it is
# a useful tool for telescope automation.
#
# This is a GPL software, created by Rumen G. Bogdanovski.
#                                              December 2013
###############################################################

use strict;
use NexStarCtl;
use Date::Parse;
use Time::Local;
use File::Basename;
use POSIX qw(strftime);
use Getopt::Std;
use if $^O eq "MSWin32", "Win32::Console::ANSI";
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my $VERSION = "0.5";

my $port;
my $verbose;

sub print_help() {
	my $N = basename($0);
	print "\n".
	      "Celestron NexStar telescope control tool v.$VERSION. Its primary purpose is to illustrate\n".
	      "how NexStarCtl module can be used, but it is a useful tool for telescope automation.\n",
	      "This is a GPL software, created by Rumen G. Bogdanovski.\n".
	      "\n".
	      "Usage: $N info [telescope]\n".
	      "       $N settime \"DATE TIME\" TZ ISDST [telescope]\n".
	      "       $N settime [telescope]\n".
	      "       $N gettime [telescope]\n".
	      "       $N setlocation LON LAT [telescope]\n".
	      "       $N getlocation [telescope]\n".
	      "       $N settrack [equatorial|north|south|azalt|pec|off] [telescope]\n".
	      "       $N gettrack [telescope]\n".
	      "       $N goto RA DE [telescope]\n".
	      "       $N gotoaz AZ ALT [telescope]\n".
	      "       $N sync RA DE [telescope]\n".
	      "       $N getrade [telescope]\n".
	      "       $N getazalt [teelescope]\n".
	      "       $N abort [telescope]\n".
	      "       $N status [telescope]\n".
	      "       $N netscan\n".
	      "options:\n".
	      "       -v verbose output\n".
	      "       -h print this help\n".
	      "[telescope]:\n".
	      "       The telescope port could be specified with this parameter or TELESCOPE_PORT\n".
	      "       environment variable can be set. Defaults depend on the operating system:\n".
	      "          Linux: /dev/ttyUSB0\n".
	      "          MacOSX: /dev/cu.usbserial\n".
	      "          Solaris: /dev/ttya\n".
	      "          Windows: COM1\n".
	      "       The network connected telescopes can be listed with \"$N netscan\"\n".
	      "       and the value of TELESCOPE_PORT for each telescope is given.\n\n".
	      "NOTE: RA and DE should be secified in J2000 and are returned in J2000.\n\n";
}


sub check_align($) {
	my ($dev) = @_;
	my $align = tc_check_align($dev);
	if (!defined $align) {
		print RED "Error reading from telescope.\n";
		return undef;
	} elsif ($align == 0) {
		print RED "The telescope is NOT aligned. Please complete the alignment routine.\n";
		return undef;
	}
	$verbose && print GREEN "The telescope is aligned.\n";
}


sub init_telescope {
	my ($tport, $check) = @_;
	my $dev = open_telescope_port($tport);
	if (!defined($dev)) {
		print RED "Can\'t open telescope on port $tport: $!\n";
		return undef;
	}

	my $res = enforce_protocol_version($dev);
	if ($res == undef) {
		print RED "Communication with the telescope on port $tport failed: $!\n";
		close_telescope_port($dev);
		return undef;
	}

	$verbose && print GREEN "The telescope port $tport is open.\n";

	if (! $check) {
		return $dev;
	}

	# Check the telescope is slewing return failure
	if (tc_goto_in_progress($dev)) {
		print RED "GOTO in progress, try again.\n";
		close_telescope_port($dev);
		return undef;
	}

	return $dev;
}


sub info {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "info: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	print "Driver: NexStarCtl v.$NexStarCtl::VERSION\n";

	my $echo = tc_echo($dev,"X");
	if ($echo ne "X") {
		print RED "info: No telescope mount found on port $port\n";
		close_telescope_port($dev);
		return undef;
	}
	print "Mount port: $port\n";

	my $model = tc_get_model($dev);
	if (!defined $model) {
		print RED "info: Error getting model. $!\n";
		close_telescope_port($dev);
		return undef;
	}
	my $model_name = get_model_name($model);
	print "Mount model: $model_name ($model)\n";

	my $version = tc_get_version($dev);
	if (!defined $version) {
		print RED "info: Error getting version. $!\n";
		close_telescope_port($dev);
		return undef;
	}
	print "HC version: $version\n";

	close_telescope_port($dev);
	return 1;
}


sub status {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "status: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my $status = tc_goto_in_progress($dev);
	if (!defined $status) {
		print RED "status: Error getting goto status. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	my $tracking = tc_get_tracking_mode($dev);
	if (!defined $tracking) {
		if ($NexStarCtl::error != -5) {
			print RED "status: Error geting tracking mode. $!\n";
			close_telescope_port($dev);
			return undef;
		} else {  # get tracking mode is unsupported on this mount
			if ($status == 0) {
				print "Telescope is either tracking or not, but GOTO is not in progress.\n";
			} else {
				print "GOTO is in progress.\n";
			}
		}
	} else {
		if (($status == 0) && ($tracking == TC_TRACK_OFF)) {
			print "Telescope is not tracking.\n";
		} elsif (($status == 0) && ($tracking != TC_TRACK_OFF)) {
			print "Telescope is tracking.\n";
		} else {
			print "GOTO is in progress.\n";
		}
	}
	close_telescope_port($dev);
	return 1;
}


sub gettime {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "gettime: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my ($date, $time, $tz, $isdst) = tc_get_time_str($dev);
	if (! defined $date) {
		print RED "gettime: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}
	print "$date $time, TZ = $tz, DST = $isdst\n";

	close_telescope_port($dev);
	return 1;
}


sub settime {
	my @params = @_;
	my $date;
	my $tz;
	my $time;
	my $isdst;

	if ($#params == 2) {
		$date = $params[0];
		$tz = round($params[1]);
		$isdst = $params[2];

	} elsif ($#params == 3) {
		$date = $params[0];
		$tz = round($params[1]);
		$isdst = $params[2];
		$port = $params[3];

	} elsif ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
		$time=time();
		$isdst = (localtime($time))[-1];
		$tz = int((timegm(localtime($time)) - $time) / 3600);
		$tz = $tz-1 if ($isdst);

	} else {
		print RED "settime: Wrong parameters.\n";
		return undef;
	}

	if (($tz < -12) or ($tz > 12)) {
		print RED "settime: Wrong time zone.\n";
		return undef;
	}

	# if $date is defined => the date is given by user
	if (defined $date) {
		$time = str2time($date);
		if (!defined $time) {
			print RED "settime: Wrong date format.\n";
			return undef;
		}
	}

	# Do not set the time if the telescope is slewing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	my ($s, $m, $h, $day, $mon, $year) = localtime($time);
	my $time_str = sprintf("%2d:%02d:%02d", $h, $m, $s);
	my $date_str = sprintf("%02d-%02d-%04d", $day, $mon + 1, $year + 1900);
	$verbose && print "settime: $date_str $time_str, TZ = $tz, DST = $isdst\n";

	if (! tc_set_time($dev, $time, $tz, $isdst)) {
		print RED "settime: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	close_telescope_port($dev);
	return 1;
}


sub getlocation {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "getlocation: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my ($lon,$lat) = tc_get_location_str($dev);
	if (! defined $lon) {
		print RED "getlocation: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}
	print "$lon, $lat\n";

	close_telescope_port($dev);
	return 1;
}


sub setlocation {
	my @params = @_;
	my $lon;
	my $lat;

	if ($#params == 1) {
		$lon = $params[0];
		$lat = $params[1];

	} elsif ($#params == 2) {
		$lon = $params[0];
		$lat = $params[1];
		$port = $params[2];

	} else {
		print RED "settime: Wrong parameters.\n";
		return undef;
	}

	# Convert strings $lon/$lat to decimal $lond/latd in decimal degrees
	my $lond = dms2d($lon);
	if ((!defined $lond) or ($lond > 180) or ($lond < -180)) {
		print RED "setlocation: Wrong longitude.\n";
		return undef;
	}

	my $latd = dms2d($lat);
	if ((!defined $latd) or ($latd > 180) or ($latd < -180)) {
		print RED "setlocation: Wrong latitude.\n";
		return undef;
	}

	# do not set location if the telescope is slewing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	$verbose && print "setlocation: lon = $lond, lat = $latd\n";

	if (! tc_set_location($dev, $lond, $latd)) {
		print RED "setlocation: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	close_telescope_port($dev);
	return 1;
}


sub settrack {
	my @params = @_;
	my $mode;

	if ($#params == 0) {
		$mode = $params[0];

	} elsif ($#params == 1) {
		$mode = $params[0];
		$port = $params[1];

	} else {
		print RED "settrack: Wrong parameters.\n";
		return undef;
	}

	my $tracking;
	if ($mode eq "equatorial") {
		$tracking = TC_TRACK_EQ;
	} elsif ($mode eq "south") {
		$tracking = TC_TRACK_EQ_SOUTH;
	} elsif ($mode eq "north") {
		$tracking = TC_TRACK_EQ_NORTH;
	} elsif ($mode eq "azalt") {
		$tracking = TC_TRACK_ALT_AZ;
	} elsif ($mode eq "pec") {
		$tracking = TC_TRACK_EQ_PEC;
	} elsif ($mode eq "off") {
		$tracking = TC_TRACK_OFF;
	} else {
		print RED "settrack: Wrong parameters.\n";
		return undef;
	}

	# do not set tracking mode if slewing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	if (! tc_set_tracking_mode($dev, $tracking)) {
		print RED "settrack: Error setting tracking mode. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	$verbose && print "settrack: $mode ($tracking)\n";

	close_telescope_port($dev);
	return 1;
}


sub gettrack {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "gettrack: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my $tracking = tc_get_tracking_mode($dev);
	if (!defined $tracking) {
		print RED "gettrack: Error geting tracking mode. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	if ($tracking == TC_TRACK_OFF) {
		print "Tracking: OFF\n";
	} elsif ($tracking == TC_TRACK_EQ_SOUTH) {
		print "Tracking: Equatorial South\n";
	} elsif ($tracking == TC_TRACK_EQ_NORTH) {
		print "Tracking: Equatorial North\n";
	} elsif ($tracking == TC_TRACK_ALT_AZ) {
		print "Tracking: Aaltazimuthal\n";
	} elsif ($tracking == TC_TRACK_EQ) {
		print "Tracking: Equatorial\n";
	} elsif ($tracking == TC_TRACK_EQ_PEC) {
		print "Tracking: Equatorial + PEC\n";
	} else {
		print "Tracking: Unknown\n";
	}

	close_telescope_port($dev);
	return 1;
}


sub gotoeq {
	my @params = @_;
	my $ra;
	my $de;

	if ($#params == 1) {
		$ra = $params[0];
		$de = $params[1];

	} elsif ($#params == 2) {
		$ra = $params[0];
		$de = $params[1];
		$port = $params[2];

	} else {
		print RED "goto: Wrong parameters.\n";
		return undef;
	}

	# convert strings $ra/$de to $rad/$ded in decimal degrees
	my $rad = hms2d($ra);
	if ((!defined $rad) or ($rad > 360) or ($rad < 0)) {
		print RED "goto: Wrong rightascension.\n";
		return undef;
	}

	my $ded = dms2d($de);
	if ((!defined $ded) or ($ded > 90) or ($ded < -90)) {
		print RED "goto: Wrong declination.\n";
		return undef;
	}

	# if telescope is slewing do nothing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	my $align = tc_check_align($dev);
	if (!defined $align) {
		print RED "goto: Error reading from telescope.\n";
		return undef;
	} elsif ($align == 0) {
		print RED "The telescope is NOT aligned. Please align before GOTO.\n";
		return undef;
	}
	$verbose && print GREEN "The telescope is aligned.\n";

	$verbose && print "goto: ra = $rad, dec = $ded\n";

	if (! tc_goto_rade_p($dev, $rad, $ded)) {
		print RED "goto: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	print "GOTO started...\n";

	close_telescope_port($dev);
	return 1;
}

sub sync {
	my @params = @_;
	my $ra;
	my $de;

	if ($#params == 1) {
		$ra = $params[0];
		$de = $params[1];

	} elsif ($#params == 2) {
		$ra = $params[0];
		$de = $params[1];
		$port = $params[2];

	} else {
		print RED "sync: Wrong parameters.\n";
		return undef;
	}

	# convert strings $ra/$de to $rad/$ded in decimal degrees
	my $rad = hms2d($ra);
	if ((!defined $rad) or ($rad > 360) or ($rad < 0)) {
		print RED "sync: Wrong rightascension.\n";
		return undef;
	}

	my $ded = dms2d($de);
	if ((!defined $ded) or ($ded > 90) or ($ded < -90)) {
		print RED "sync: Wrong declination.\n";
		return undef;
	}

	# if telescope is slewing do nothing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	my $align = tc_check_align($dev);
	if (!defined $align) {
		print RED "sync: Error reading from telescope.\n";
		return undef;
	} elsif ($align == 0) {
		print RED "The telescope is NOT aligned. Please align before sync.\n";
		return undef;
	}
	$verbose && print GREEN "The telescope is aligned.\n";

	$verbose && print "sync: ra = $rad, dec = $ded\n";

	if (! tc_sync_rade_p($dev, $rad, $ded)) {
		print RED "sync: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	close_telescope_port($dev);
	return 1;
}


sub getrade {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "getrade: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my ($ra,$de) = tc_get_rade_p($dev);
	if (!defined $ra) {
		print RED "getrade: Error geting ra/de. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	# convert digital degrees $ra/$de to strings and print them
	print d2hms($ra) . ", " . d2dms($de)."\n";

	close_telescope_port($dev);
	return 1;
}


sub gotoaz {
	my @params = @_;
	my $az;
	my $alt;

	if ($#params == 1) {
		$az = $params[0];
		$alt = $params[1];

	} elsif ($#params == 2) {
		$az = $params[0];
		$alt = $params[1];
		$port = $params[2];

	} else {
		print RED "gotoaz: Wrong parameters.\n";
		return undef;
	}

	# convert strings $az/$alt to $az/$alt in decimal degrees
	my $azd = dms2d($az);
	if (!defined $azd) {
		print RED "gotoaz: Wrong azimuth.\n";
		return undef;
	}

	my $altd = dms2d($alt);
	if ((!defined $altd) or ($altd > 90) or ($altd < -90)) {
		print RED "gotoaz: Wrong altitude.\n";
		return undef;
	}

	# if telescope is slewing do nothing
	# so set second parameter to 1
	my $dev = init_telescope($port, 1);
	return undef if (! defined $dev);

	my $align = tc_check_align($dev);
	if (!defined $align) {
		print RED "gotoaz: Error reading from telescope.\n";
		return undef;
	} elsif ($align == 0) {
		print RED "The telescope is NOT aligned. Please align before GOTO.\n";
		return undef;
	}
	$verbose && print GREEN "The telescope is aligned.\n";

	$verbose && print "gotoaz: az = $azd, alt = $altd\n";

	if (! tc_goto_azalt_p($dev, $azd, $altd)) {
		print RED "gotoaz: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	print "GOTO started...\n";

	close_telescope_port($dev);
	return 1;
}


sub getazalt {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "getazalt: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my ($az,$alt) = tc_get_azalt_p($dev);
	if (!defined $az) {
		print RED "getazalt: Error geting az/alt. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	print d2dms($az) . ", " . d2dms($alt)."\n";

	close_telescope_port($dev);
	return 1;
}


sub abort {
	my @params = @_;
	if ($#params <= 0) {
		if (defined $params[0]) {
			$port = $params[0];
		}
	} else {
		print RED "abort: Wrong parameters.\n";
		return undef;
	}

	my $dev = init_telescope($port);
	return undef if (! defined $dev);

	my $reult = tc_goto_cancel($dev);
	if (!defined $reult) {
		print RED "abort: Failed. $!\n";
		close_telescope_port($dev);
		return undef;
	}

	$verbose && print "GOTO aborted.\n";

	close_telescope_port($dev);
	return 1;
}


sub netscan {
	eval "use Net::Bonjour";
	if ($@) {
		print RED "This feature is disabled to enable it Net::Bonjour should be installed!\n";
		return undef;
	}
	my $res = Net::Bonjour->new('nexbridge');

	$res->discover();

	if ( $res->entries == 0) {
		print "\nNo telescopes discovered!\n";
		print YELLOW "To discover the network connected telescopes they should be\n";
		print YELLOW "exported via Bonjour with nexbridge (See perldoc NexStarCtl)\n\n";
		return 1;
	}

	print "\n";
	printf "%-30s %s\n", "NAME", "TELESCOPE_PORT";
	printf "%-30s %s\n", "===============", "==============";

	$res->discover();
	foreach my $entry ($res->entries) {
		printf "%-30s %s://%s:%s (%s)\n", $entry->name, $res->protocol, $entry->hostname, $entry->port, $entry->address;
	}
	print "\n";

        return 1;
}


sub main() {
	my %options = ();

	my $command = shift @ARGV;

	if (defined $ENV{TELESCOPE_PORT}) {
		$port = $ENV{TELESCOPE_PORT};
	} else {
		if ($^O eq 'linux') {
			$port = "/dev/ttyUSB0";
		} elsif ($^O eq 'darwin') {
			$port = "/dev/cu.usbserial";
		} elsif ($^O eq 'solaris') {
			$port = "/dev/ttya";
		} elsif ($^O eq 'MSWin32') {
			$port = "COM1";
		}
	}

	if (getopts("vh", \%options) == undef) {
		exit 1;
	}

	if (defined($options{h}) or (!defined($command))) {
		print_help();
		exit 1;
	}

	if(defined($options{v})) {
		$verbose = 1;
	}

	if ($command eq "info") {
		if (! info(@ARGV)) {
			$verbose && print RED "Get info returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get info succeeded.\n";
		exit 0;

	} elsif ($command eq "gettime") {
		if (! gettime(@ARGV)) {
			$verbose && print RED "Get time returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get time succeeded.\n";
		exit 0;

	} elsif ($command eq "settime") {
		if (! settime(@ARGV)) {
			$verbose && print RED "Set time returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Set time succeeded.\n";
		exit 0;

	} elsif ($command eq "getlocation") {
		if (! getlocation(@ARGV)) {
			$verbose && print RED "Get location returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get location succeeded.\n";
		exit 0;

	} elsif ($command eq "setlocation") {
		if (! setlocation(@ARGV)) {
			$verbose && print RED "Set location returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Set location succeeded.\n";
		exit 0;

	} elsif ($command eq "settrack") {
		if (! settrack(@ARGV)) {
			$verbose && print RED "Set track returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Set track succeeded.\n";
		exit 0;

	} elsif ($command eq "gettrack") {
		if (! gettrack(@ARGV)) {
			$verbose && print RED "Get track returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get track succeeded.\n";
		exit 0;

	} elsif ($command eq "goto") {
		if (! gotoeq(@ARGV)) {
			$verbose && print RED "GOTO ra/de returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "GOTO ra/de succeeded.\n";
		exit 0;

	} elsif ($command eq "sync") {
		if (! sync(@ARGV)) {
			$verbose && print RED "SYNC ra/de returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "SYNC ra/de succeeded.\n";
		exit 0;

	} elsif ($command eq "gotoaz") {
		if (! gotoaz(@ARGV)) {
			$verbose && print RED "GOTO az/alt returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "GOTO az/alt succeeded.\n";
		exit 0;

	} elsif ($command eq "getrade") {
		if (! getrade(@ARGV)) {
			$verbose && print RED "Get ra/de returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get ra/de succeeded.\n";
		exit 0;

	} elsif ($command eq "getazalt") {
		if (! getazalt(@ARGV)) {
			$verbose && print RED "Get az/alt returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Get az/alt succeeded.\n";
		exit 0;

	} elsif ($command eq "abort") {
		if (! abort(@ARGV)) {
			$verbose && print RED "Abort returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Abort succeeded.\n";
		exit 0;

	} elsif ($command eq "status") {
		if (! status(@ARGV)) {
			$verbose && print RED "Status returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Status succeeded.\n";
		exit 0;

	} elsif ($command eq "netscan") {
		if (! netscan()) {
			$verbose && print RED "Netscan returned error.\n";
			exit 1;
		}
		$verbose && print GREEN "Netscan succeeded.\n";
		exit 0;

	} elsif ($command eq "-h") {
		print_help();
		exit 0;

	} else {
		print RED "There is no such command \"$command\".\n";
	}
}

main;
