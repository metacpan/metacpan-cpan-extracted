#!/usr/bin/env perl

use strict;
use warnings;
use Archive::Tar;

use Test;
use POSIX qw(tzset);

BEGIN { plan test => 85 }

use NetAthlon2::RAW;

my $testfiles = {
	'Bike2009-07-02 5-54pm.RAW' => {
		'TimeZone' => 'EDT',
		'Tests' => {
			'Distance' => 0.03,
			'Elapsed Time' => 12.76,
			'Average Cadence' => 28,
			'Average Watts' => 47,
			'Start Time' => 1246557240,
			'Check Points' => 2,
			'Max Cadence' => 28,
			'Max Speed' => 7.2,
			'Max Watts' => 47,
		},
	},

	'Bike2009-08-20 4-53pm.RAW' => {
		'TimeZone' => 'EDT',
		'Tests' => {
			'Distance' => 32.90,
			'Elapsed Time' => 6951.49,
			'Average Cadence' => 87.6523,
			'Average Watts' => 187.8944,
			'Start Time' => 1250787180,
			'Check Points' => 465,
			'Max Watts' => 419,
			'Max Speed' => 24.6,
			'Max Cadence' => 97,
			'Max Heart Rate' => 165,
		},
	},

	# Test a larger time delta between filename and contents
	'Bike2009-09-21 4-30pm.RAW' => {
		'TimeZone' => 'EDT',
		'timeDelta' => 5,
		'Tests' => {
			'Distance' => 0.60,
			'Elapsed Time' => 160.43,
			'Average Cadence' => 71.7143,
			'Average Watts' => 114,
			'Start Time' => 1253550420,
			'Check Points' => 12,
			'Max Watts' => 152,
			'Max Speed' => '15.3',
			'Max Cadence' => 80,
			'Max Heart Rate' => 106,
		},
	},

	# Test with a extremely unrealistic power value in the first checkpoint
	# and a distance that does not match the elapsed time because of warmup
	# time
	'Bike2009-10-25 5-05pm.RAW' => {
		'TimeZone' => 'EDT',
		'Tests' => {
			'Distance' => 16.87,
			'Elapsed Time' => 2700,
			'Average Cadence' => 95.5222,
			'Average Watts' => 179.5389,
			'Start Time' => 1256490300,
			'Check Points' => 181,
			'Max Watts' => 323,
			'Max Speed' => '21.9',
			'Max Cadence' => 127,
			'Max Heart Rate' => 164,
		},
	},

	# Test the am/pm conversion
	'Bike2009-11-08 12-13pm.RAW' => {
		'TimeZone' => 'EST',
		'Tests' => {
			'Distance' => 19.78,
			'Elapsed Time' => 3600,
			'Average Cadence' => 83.2833,
			'Average Watts' => 259.2833,
			'Start Time' => 1257700380,
			'Check Points' => 241,
			'Max Watts' => 805,
			'Max Speed' => '32.6',
			'Max Cadence' => 107,
			'Max Heart Rate' => 208,
		},
	},

	# A test where the start time and time delta cross the hour boundry.
	'Bike2009-11-29 4-00pm.RAW' => {
		'TimeZone' => 'EST',
		'Tests' => {
			'Distance' => 24.59,
			'Elapsed Time' => 4670.69,
			'Start Time' => 1259528340,
			'Check Points' => 313,
			'Average Speed' => 18.9367,
			'Average Cadence' => 97.6218,
			'Average Watts' => 233.2083,
		},
	},

	# A test with a shorter sample rate
	'Bike2009-12-01 5-14pm.RAW' => {
		'TimeZone' => 'EST',
		'Tests' => {
			'Distance' => 21.19,
			'Elapsed Time' => 3600,
			'Start Time' => 1259705640,
			'Sample Rate' => 5,
			'Check Points' => 721,
			'Average Speed' => 21.1486,
			'Average Cadence' => 87.4014,
			'Average Watts' => 299.2361,
		},
	},
};

my $t = NetAthlon2::RAW->new ();

# Hack to unpack the .RAW files
# (cant have a filename with a space in the MANIFEST file).
my $tar = Archive::Tar->new;
chdir('t');
$tar->read('test.tar');
$tar->extract();

sub round_off {
	my ($value) = @_;

	return ((int (($value * 10000) + 0.5)) / 10000 + 0.0000);
}

for my $file ( keys %$testfiles ) {
	$NetAthlon2::RAW::timeDelta = ( exists $testfiles->{$file}->{'timeDelta'} )
		? $testfiles->{$file}->{'timeDelta'}
		: 1;

	# Set the timezone, so our ./Build test works with machines
	# not in the same timezone as the author is in.
	if ( exists $testfiles->{$file}->{'TimeZone'} ) {
		$ENV{'TZ'} = $testfiles->{$file}->{'TimeZone'};
		tzset()
			if ( $^O ne 'MSWin32' );
	} elsif ( defined $ENV{'TZ'} ) {
		delete $ENV{'TZ'};
	}

	my $d = $t->parse($file);
	ok(ref $d, 'HASH');
	for my $test ( keys %{$testfiles->{$file}->{'Tests'}} ) {
		if ( $test eq 'Check Points' ) {
			ok(scalar @{$d->{$test}}, $testfiles->{$file}->{'Tests'}->{$test}, "Failed test ($test) for file ($file)");

		# Skip the Start Time validation on M$ systems because of
		# the complications with timezones.
		} elsif ( $test eq 'Start Time' ) {
			if ( $^O ne 'MSWin32' ) {
				ok($d->{$test}, $testfiles->{$file}->{'Tests'}->{$test}, "Failed test ($test), in file ($file)")
			} else {
				ok (0, 0, "# Not testing Start Time on Windows");
			}
		} else {
			ok(&round_off($d->{$test}), $testfiles->{$file}->{'Tests'}->{$test}, "Failed test ($test), in file ($file)");
		}
	}

	# Now test the na2png script with our data file
	my $rc = system ("$^X ../script/na2png \"$file\"");
	ok ($rc, 0, "na2png failed ($rc)\n");

	my $imgfile = $file;
	$imgfile =~ s/\.RAW$/.png/;
	ok (-s $imgfile > 0, 1, "na2png output file should not be zero length($imgfile)\n");
}

exit 0;
