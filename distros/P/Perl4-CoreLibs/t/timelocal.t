use warnings;
use strict;

use Test::More tests => 85;

require_ok "timelocal.pl";

my $min_ok_year = $^O eq "VMS" || !defined((localtime(-259200))[0]) ? 1970 :
	$^O eq "vos" ? 1980 : 1904;
my $current_year = (gmtime)[5] + 1900;

foreach(
	#year,mon,day,hour,min,sec
	[1904,  2, 29,  0,  0,  0],
	[1950,  4, 12,  9, 30, 31],
	[1969, 12, 31, 16, 59, 59],
	[1970,  1,  3, 00, 00, 00],
	[1980,  2, 28, 12, 00, 00],
	[1980,  2, 29, 12, 00, 00],
	[1996,  2, 29,  0,  0,  0],
	[1999, 12, 31, 23, 59, 59],
	[2000,  1,  1, 00, 00, 00],
	[2000,  2, 29,  0,  0,  0],
	[2004,  2, 29,  0,  0,  0],
	[2010, 10, 12, 14, 13, 12],
	[2020,  2, 29, 12, 59, 59],
	[2030,  7,  4, 17, 07, 06],
) {
	my($year, $mon, $mday, $hour, $min, $sec) = @$_;
	SKIP: {
		skip "$year is too early for this OS", 4
			if $year < $min_ok_year;
		my @out = ($sec, $min, $hour, $mday, $mon-1, $year-1900);
		foreach my $year_in (
			$year,
			$year-$current_year >= -40 &&
					$year-$current_year <= 40 ?
				$year % 100 : $year,
		) {
			my @in = ($sec, $min, $hour, $mday, $mon-1, $year_in);
			is_deeply [(localtime(&timelocal(@in)))[0..5]], \@out,
				"localtime(timelocal(@{[join(q(, ), @in)]}))";
			is_deeply [(gmtime(&timegm(@in)))[0..5]], \@out,
				"gmtime(timegm(@{[join(q(, ), @in)]}))";
		}
	}
}


foreach(
	# month too large
	[1995, 13, 01, 01, 01, 01],
	# day too large
	[1995, 02, 30, 01, 01, 01],
	# hour too large
	[1995, 02, 10, 25, 01, 01],
	# minute too large
	[1995, 02, 10, 01, 60, 01],
	# second too large
	[1995, 02, 10, 01, 01, 60],
) {
	my($year, $mon, $mday, $hour, $min, $sec) = @$_;
	foreach my $year_in ($year, $year % 100) {
		my @in = ($sec, $min, $hour, $mday, $mon-1, $year_in);
		eval { &timelocal(@in) };
		like $@, qr/.*out of range.*/, 'invalid time caused an error';
		eval { &timegm(@in) };
		like $@, qr/.*out of range.*/, 'invalid time caused an error';
	}
}

is &timelocal(0,0,1,1,0,1990) - &timelocal(0,0,0,1,0,1990), 3600,
	'one hour difference between two calls to timelocal';

is &timelocal(1,2,3,1,0,2000) - &timelocal(1,2,3,31,11,1999), 24 * 3600,
	'one day difference between two calls to timelocal';

# Diff beween Jan 1, 1980 and Mar 1, 1980 = (31 + 29 = 60 days)
is &timegm(0,0,0, 1, 2, 1980) - &timegm(0,0,0, 1, 0, 1980), 60 * 24 * 3600,
	'60 day difference between two calls to timegm';

# bugid #19393
# At a DST transition, the clock skips forward, eg from 01:59:59 to
# 03:00:00. In this case, 02:00:00 is an invalid time, and should be
# treated like 03:00:00 rather than 01:00:00 - negative zone offsets used
# to do the latter
{
	my $hour = (localtime(&timelocal(0, 0, 2, 7, 3, 2002)))[2];
	# testers in US/Pacific should get 3,
	# other testers should get 2
	ok $hour == 2 || $hour == 3, 'hour should be 2 or 3';
}

eval { &timelocal(0,0,0,29,1,1900) };
like $@, qr/Day '29' out of range 1\.\.28/, 'does not accept leap day in 1900';
eval { &timegm(0,0,0,29,1,1900) };
like $@, qr/Day '29' out of range 1\.\.28/, 'does not accept leap day in 1900';
eval { &timelocal(0,0,0,29,1,2100) };
like $@, qr/Day '29' out of range 1\.\.28/, 'does not accept leap day in 2100';
eval { &timegm(0,0,0,29,1,2100) };
like $@, qr/Day '29' out of range 1\.\.28/, 'does not accept leap day in 2100';

1;
