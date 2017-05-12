#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Time::HiRes qw(time);

use lib '../lib', 'lib';

use_ok('SMB::Time', qw(from_nttime to_nttime));

sub rounded ($$) { abs($_[1] - $_[0]) < 0.0001 ? $_[1] : $_[0] }

my $time = time;
my $nttime = to_nttime($time);
note "time=$time nttime=$nttime";
my $time2 = rounded(from_nttime($nttime), $time);
is($time2, $time, "to_nttime + from_nttime");

$nttime = 130158657277172029;  # 2013-06-16 15:15:27 GMT
$time = from_nttime($nttime);
is(int($time), 1371392127, "from_nttime($nttime)");
