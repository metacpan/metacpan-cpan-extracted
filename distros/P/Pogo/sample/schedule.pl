#!/usr/local/bin/perl
# schedule.pl - sample script for Pogo - 1999 Sey
use Pogo;
use Carp;
use strict;

# Option flags
my $Del;
if( $ARGV[0] eq '-h' ) {
	usage();
} elsif( $ARGV[0] eq '-d' ) {
	$Del = 1;
	shift;
}

# Get command line arguments
my $Date = shift;
my $Data = shift;

# Split $Date and supplement defaults
my($Year, $Month, $Day, $Index);
my($TYear, $TMonth, $TDay) = Schedule::today();
if( defined $Date ) {
	($Year, $Month, $Day, $Index) = 
		$Date =~ /^(?:(?:(\d+)\/)?(\d+)\/)?(\d+)(?::(\d+))?$/;
	$Year ||= $TYear;
	$Month ||= $TMonth;
	Schedule::ymdcheck($Year, $Month, $Day);
} else {
	($Year, $Month, $Day) = ($TYear, $TMonth, $TDay);
} 

# Connect database and get root
my $Pogo = new Pogo "sample.cfg";
my $Root = $Pogo->root_tie;

# Create (if necessary) and get Schedule object
$Root->{schedule} = new Schedule unless exists $Root->{schedule};
my $Schedule = $Root->{schedule};

# Do the job
if( $Del ) {
	$Schedule->del($Year, $Month, $Day, $Index);
} elsif( defined $Data ) {
	$Schedule->add($Year, $Month, $Day, $Data);
}
$Schedule->print($Year, $Month, $Day);

# Exit

sub usage {
	(my $script = $0) =~ s/^.*\///;
	print <<END;
usage
  $script                 : show today's schedule
  $script date            : show specified day's schedule
  $script date 'schedule' : add specified day's schedule
  $script -d date         : delete specified day's schedule
  $script -d date:N       : delete specified day's N'th schedule
  $script -h              : show this help
date format
  Y/M/D : Y for year(must be 4-digits), M for month, D for day, all are numbers
  M/D   : same as above with current year
  D     : same as above with current year and month
END
	exit(1);
}

# ---------------------------------------------------------------------
# Schedule class
# Note that the code as follows is an ordinary Perl class definition.
# It does not include special code for database access.
# ---------------------------------------------------------------------
package Schedule;
use Carp;
use strict;

sub new {
	my $class = shift;
	bless {}, $class;
}

sub add {
	my($self, $year, $month, $day, $data) = @_;
	ymdcheck($year, $month, $day);
	$self->{$year}[$month - 1][$day - 1] = []
		unless defined $self->{$year}[$month - 1][$day - 1];
	push @{$self->{$year}[$month - 1][$day - 1]}, $data;
}

sub del {
	my($self, $year, $month, $day, $index) = @_;
	ymdcheck($year, $month, $day);
	if( $index > 0 ) {
		splice @{$self->{$year}[$month - 1][$day - 1]}, $index - 1, 1;
	} else {
		@{$self->{$year}[$month - 1][$day - 1]} = ();
	}
}

sub print {
	my($self, $year, $month, $day) = @_;
	ymdcheck($year, $month, $day);
	my $data = $self->{$year}[$month - 1][$day - 1];
	if( ref($data) eq 'ARRAY' ) {
		print "$year/$month/$day\n";
		for(my $j = 1; $j <= @$data; $j++) {
			print " $j: ",$data->[$j - 1],"\n";
		}
	}
}

# utility functions (not methods)

sub ymdcheck {
	my($year, $month, $day) = @_;
	croak "$year is not a valid year" unless $year =~ /^\d{4}$/;
	croak "$month is not a valid month" unless 
		$month =~ /^\d{1,2}$/ && $month > 0 && $month < 13;
	croak "$year/$month/$day is not a valid day" unless 
		$day =~ /^\d{1,2}$/ && $day > 0 && $day <= daymonth($year, $month);
}

sub leapyear {
	my($year) = @_;
	$year % 4 == 0 && $year % 100 != 0 || $year % 400 == 0;
}

sub daymonth {
	my($year, $month) = @_;
	return 29 if $month == 2 && leapyear($year);
	(31,28,31,30,31,30,31,31,30,31,30,31,31)[$month - 1];
}

sub today {
	my($year, $month, $day) = (localtime)[5,4,3];
	$year += 1900;
	$month++;
	($year, $month, $day);
}

sub nextday {
	my($year, $month, $day) = @_;
	$day++;
	$month++, $day = 1 if $day > daymonth($year, $month);
	$year++, $month = 1 if $month > 12;
	($year, $month, $day);
}
