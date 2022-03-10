#!/usr/bin/perl

use Test::More qw( no_plan );
use strict;
use warnings;
use lib './lib';
use DateTime;
use DateTime::Duration;
use DateTime::Format::Strptime;

BEGIN
{
    use_ok( 'Module::Generic::DateTime' ) || BAIL_OUT( "Unable to load Module::Generic::DateTime" );
};

my $hash =
{
    year => 2021,
    month => 3,
    day => 31,
    hour => 9,
    minute => 12,
    second => 10,
    time_zone => 'Asia/Tokyo',
};
my $dt = DateTime->new( %$hash );
my $fmt = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S',
    locale => 'en_GB',
);
$dt->set_formatter( $fmt );
# my $dt2 = DateTime->now( time_zone => 'local' );
# my $dt2 = DateTime->now( time_zone => 'Asia/Tokyo' );
## my $dt2 = DateTime->now( time_zone => 'GMT' );
my $dt2 = DateTime->new(
    year => 2021,
    month => 3,
    day => 19,
    hour => 12,
    minute => 8,
    second => 15,
    time_zone => 'UTC',
);
$dt2->set_formatter( $fmt );
my $now = $dt2->epoch;
my $iso = $dt2->iso8601;
my $iso2 = q{2021-03-31T10:21:48+0700};
my $iso3 = q{2021-03-31T06:21:48+0700};
ok( $dt > $dt2, "Is $dt (" . overload::StrVal( $dt ) . ") greater than $dt2 (" . overload::StrVal( $dt2 ) . ") ?" );
my $dbt1 = Module::Generic::DateTime->new( $dt );
my $dbt2 = Module::Generic::DateTime->new( $dt2 );
# diag( "Using object overload" );
ok( $dbt1 > $now, "is $dbt1 (" . overload::StrVal( $dbt1 ) . ") greater than $now (" . overload::StrVal( $now ) . ") ?" );
# diag( "Using object overload (with iso string)" );
ok( $dbt1 > $iso, "is $dbt1 (" . overload::StrVal( $dbt1 ) . ") greater than $iso (" . overload::StrVal( $iso ) . ") ?" );
# diag( "Comparing object to string (with iso)" );
ok( !( $dbt1 > $iso2 ), "is $dbt1 (" . overload::StrVal( $dbt1 ) . ") greater than $iso2 (" . overload::StrVal( $iso2 ) . ") ?" );
# diag( "Comparing object to string (with iso)" );
ok( $dbt1 > $iso3, "is $dbt1 (" . overload::StrVal( $dbt1 ) . ") greater than $iso3 (" . overload::StrVal( $iso3 ) . ") ?" );
my $dur = DateTime::Duration->new( days => 2 );

# diag( "\nUsing Module::Generic::DateTime." );
my $res = ( $dbt2 + $dur );
isa_ok( $res, 'Module::Generic::DateTime', "Trying to do : \$dbt ($dbt2) + Duration (2 days [$dur]):" );

# diag( $res->stringify );
ok( $res->stringify eq '2021-03-21 12:08:15' );

$res = ( $dbt1 - $dbt2 );
isa_ok( $res, 'Module::Generic::DateTime::Interval', "Subtract \$dbt2 ($dbt2) from \$dbt1 ($dbt1)" );
# diag( "DateTime duration dump:\n", $res->dump );

is( $res->weeks, 1, "Number of weeks" );
$res->weeks( 2 );
# diag( "DateTime duration dump:\n", $res->dump );
# diag( "Increasing number of days using lvalue..." );
$res->days = 3;
is( $res->days, 3, "Number of days" );
# $res->days++;
# diag( "DateTime duration dump:\n", $res->dump );
# diag( "Multiplying duration $res by 2 using *" );
my $res2 = ( $res * 2 );
# diag( "Multiplying duration $res by 2 using *=" );
$res *= 2;
# diag( "$res is now:\n", $res->dump );

# diag( "Before subtraction assignment: $dbt1" );
$dbt1 -= 2;
# diag( "After subtraction assignment: $dbt1" );
# diag( "Adding back 4..." );
$dbt1 += 4;
# diag( "After addition assignment: $dbt1" );

my $dt_now2 = DateTime->now;
my $now2 = Module::Generic::DateTime->new;
isa_ok( $now2 => 'Module::Generic::DateTime' );
is( $now2->year, $dt_now2->year, 'default year' );
is( $now2->month, $dt_now2->month, 'default month' );
is( $now2->day, $dt_now2->day, 'default day' );
is( $now2->time_zone->name, $dt_now2->time_zone->name, 'default time zone' );

done_testing;
