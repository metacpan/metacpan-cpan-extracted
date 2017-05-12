# -*- perl -*-

use Test::More tests => 8394;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Calendar;
use TaskForest::LocalTime;

BEGIN {
    use_ok( 'TaskForest::Calendar'  );
}

my $got;
my ($y, $m, $dow);
my $expected = [];


# get data for all dates between 1/1/2000 and 12/31/2099

my $day_data   = {};
my ($year, $month, $day);
my $last_year  = 2009;
my $last_month = 1;
my $dt = DateTime->new(year   => $last_year,
                       month  => 01,
                       day    => 1,
                       hour   => 0,
                       minute => 0,
                       second => 0,
    );

while ($dt->year() < 2109) {
    #print "Looking at ", $dt->year(), "/01/01\n" if $dt->month() == 1 and $dt->day == 1;
    
    $dow   = $dt->day_of_week();
    $dow   = 0 if $dow == 7;

    $year  = $dt->year();
    $month = $dt->month();
    $day   = $dt->day();
    
    push (@{$day_data->{$year}->{$month}->{$dow}}, $day);

    if ($month != $last_month) {
        foreach my $d (0..6) {
            #print "Looking at $last_year, $last_month, $d\n";
            $got = &TaskForest::Calendar::findDaysOfWeek($last_year, $last_month, $d);
            $expected = $day_data->{$last_year}->{$last_month}->{$d};
            is_deeply($got, $expected);
        }
    }

    $last_month = $month;
    $last_year  = $year;

    $dt->add(days => 1);
}

