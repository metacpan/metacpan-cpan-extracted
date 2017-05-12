#!/usr/bin/perl -w

use strict;

# set the lib to include 'mylib' in the same dir as this script
use File::Spec::Functions;
use FindBin;
use lib (catdir($FindBin::Bin,"mylib"));

# start the testing
use Test::More tests => 46;

BEGIN { use_ok "Number::Compare::Date" }

use Date::Parse;

my $y2k_time = str2time("2000-01-01");

foreach my $y2k (str2time("2000-01-01"),
		 "2000-01-01T00:00:00",
		 "1 Jan 2000")
{
my $y2k_comp;
$y2k_comp = Number::Compare::Date->new("<$y2k");
ok($y2k_comp->($y2k_time-1));
ok(!$y2k_comp->($y2k_time));
ok(!$y2k_comp->($y2k_time+1));

$y2k_comp = Number::Compare::Date->new("<=$y2k");
ok($y2k_comp->($y2k_time-1));
ok($y2k_comp->($y2k_time));
ok(!$y2k_comp->($y2k_time+1));

$y2k_comp = Number::Compare::Date->new("$y2k");
ok(!$y2k_comp->($y2k_time-1));
ok($y2k_comp->($y2k_time));
ok(!$y2k_comp->($y2k_time+1));

$y2k_comp = Number::Compare::Date->new(">=$y2k");
ok(!$y2k_comp->($y2k_time-1));
ok($y2k_comp->($y2k_time));
ok($y2k_comp->($y2k_time+1));

$y2k_comp = Number::Compare::Date->new(">$y2k");
ok(!$y2k_comp->($y2k_time-1));
ok(!$y2k_comp->($y2k_time));
ok($y2k_comp->($y2k_time+1));

}





