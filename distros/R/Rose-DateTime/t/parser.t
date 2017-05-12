#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN 
{
  use_ok('Rose::DateTime::Util');
  use_ok('Rose::DateTime::Parser');
}

# Test to see if we can creat local DateTimes
eval { DateTime->now(time_zone => 'local') };

# Use UTC if we can't
Rose::DateTime::Util->time_zone('UTC')  if($@);

my $default_parser = Rose::DateTime::Parser->new();

is($default_parser->time_zone, Rose::DateTime::Util->time_zone, 'time_zone()');

my $d1 = $default_parser->parse_date('1/1/2002');
my $d2 = Rose::DateTime::Util::parse_date('1/1/2002', 'floating');

ok($d1 == $d2, 'parse_date() 1');

my $floating_parser = Rose::DateTime::Parser->new(time_zone => 'floating');

$d1 = $floating_parser->parse_date('1/1/2002');
$d2 = Rose::DateTime::Util::parse_date('1/1/2002', 'floating');

ok($d1 == $d2, 'parse_date() 2');

is($default_parser->european, 0, 'european 1');
is($floating_parser->european, 0, 'european 2');

Rose::DateTime::Util->european_dates(1);

$d1 = $default_parser->parse_date('1/2/2002');
$d2 = Rose::DateTime::Util::parse_date('2/1/2002');
ok($d1 == $d2, 'parse_date() 3');

$default_parser->european(1);
$d1 = $default_parser->parse_date('2/1/2002');
$d2 = Rose::DateTime::Util::parse_date('2/1/2002');
ok($d1 == $d2, 'parse_date() 4');

Rose::DateTime::Util->european_dates(0);

$d1 = $default_parser->parse_date('2/1/2002');
$d2 = Rose::DateTime::Util::parse_date('1/2/2002');
ok($d1 == $d2, 'parse_date() 5');

Rose::DateTime::Util->european_dates(1);
$default_parser->european(undef);
$d1 = $default_parser->parse_date('2/1/2002');
$d2 = Rose::DateTime::Util::parse_date('2/1/2002');
ok($d1 == $d2, 'parse_date() 6');

$default_parser->european(0);
$d1 = $default_parser->parse_date('1/2/2002');
$d2 = Rose::DateTime::Util::parse_date('2/1/2002');
ok($d1 == $d2, 'parse_date() 7');

$d1 = $default_parser->parse_european_date('2/1/2002');
$d2 = Rose::DateTime::Util::parse_date('2/1/2002');
ok($d1 == $d2, 'parse_date() 8');
