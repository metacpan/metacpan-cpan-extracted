package main;

require 'timelocal.pl';

package SyslogScan::ParseDate;
use strict;

my $gDefaultYear;
sub setDefaultYear
{
    $gDefaultYear = shift;
}

my $ONE_MONTH = 30*24*60*60;
my $ELEVEN_MONTH = 11 * $ONE_MONTH;

my @gMonthList = qw ( jan feb mar apr may jun jul aug sep oct nov dec );
my %gMonthTable = ();
my ($i, $month);
foreach $month (@gMonthList)
{
    $gMonthTable{$month} = $i++;
}

sub parseDate {
    my $date = shift;

    my $defaultYear = $gDefaultYear;

    # assume pure number is already in time_t format
    return $date if ($date !~ /[^\d]/);

    if ($date =~ /(\d\d?)\.(\d\d?)\.(\d\d) (\d\d):(\d\d):(\d\d)/)
    {
	# 06.01.96 01:20:30 is June 1 1996 at 1:20:30
	#print STDERR "$6,$5,$4,$2,$1,$3 resolves to ", scalar(localtime(timelocal($6,$5,$4,$2,$1,$3))), "\n";
	return ::timelocal($6,$5,$4,$2,$1-1,$3);
    }

    # assume date is in syslog format
    my ($engMonth, $mday, $year, $hour, $min, $sec) =
	$date =~ /(\w\w\w) ?(\d\d?)( \d\d\d\d)? (\d\d):(\d\d):(\d\d)/ or
	    die "unknown date format: $date";

    $year -= 1900 if defined $year;   #compatibility with timelocal()
    
    $engMonth =~ tr/A-Z/a-z/;
    my $mon;
    defined ($mon = $gMonthTable{$engMonth}) or
	die "unknown month: $engMonth";

    if (! defined($year))
    {
	# no year was specified, look for default
	if (defined($defaultYear))
	{
	    $defaultYear > 1970 and $defaultYear < 2030 or
		die "default year $defaultYear does not look right";
	    $year = $defaultYear - 1900;
	}
	else
	{
	    # try to guess time closest to now
	    my $now = time;
	    $year = (localtime($now))[5];

	    my $candidate = ::timelocal($sec, $min, $hour, $mday, $mon, $year);

	    if (($candidate - $now) > $ONE_MONTH)
	    {
		# log entry was probably made last year
		$year--;
	    }
	    elsif (($now - $candidate) > $ELEVEN_MONTH)
	    {
		# log entry was made 'next year', possible if
		# computers on LAN have different times
		$year++;
	    }
	}
    }

    my $parsedDate = ::timelocal($sec, $min, $hour, $mday, $mon, $year);
    $parsedDate == -1 and die "could not parse date: $date";
    return $parsedDate;
};

1;
