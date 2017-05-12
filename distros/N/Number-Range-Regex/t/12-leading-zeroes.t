#!perl -w
$|++;

use strict;
use Test::More tests => 59;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

my ($r1, $r2);
$r1 = rangespec('-inf..+inf', {no_leading_zeroes => 0});
ok($r1);
ok(-99    =~ /^$r1$/);
ok("-099" =~ /^$r1$/);
ok(-9     =~ /^$r1$/);
ok("-09"  =~ /^$r1$/);
ok(0      =~ /^$r1$/);
ok("00"   =~ /^$r1$/);
ok(9      =~ /^$r1$/);
ok("09"   =~ /^$r1$/);
ok(99     =~ /^$r1$/);
ok("099"  =~ /^$r1$/);

$r2 = range(undef, undef, {allow_wildcard => 1, no_leading_zeroes => 0});
ok($r2);
ok($r1->regex eq $r2->regex);
ok($r1->to_string eq $r2->to_string);

$r1 = rangespec('-inf..+inf', {no_leading_zeroes => 1});
ok($r1);
ok(-99    =~ /^$r1$/);
ok("-099" !~ /^$r1$/);
ok(-9     =~ /^$r1$/);
ok("-09"  !~ /^$r1$/);
ok(0      =~ /^$r1$/);
ok("00"   !~ /^$r1$/);
ok(9      =~ /^$r1$/);
ok("09"   !~ /^$r1$/);
ok(99     =~ /^$r1$/);
ok("099"  !~ /^$r1$/);

$r1 = rangespec('0..+inf', {no_leading_zeroes => 1});
ok(-1    !~ /^$r1$/);
ok(0     =~ /^$r1$/);
ok("00"  !~ /^$r1$/);
ok(1     =~ /^$r1$/);
ok("01"  !~ /^$r1$/);
ok(10    =~ /^$r1$/);
ok("010" !~ /^$r1$/);

$r1 = rangespec('-inf..-1', {no_leading_zeroes => 1});
ok(0      !~ /^$r1$/);
ok("00"   !~ /^$r1$/);
ok(-1     =~ /^$r1$/);
ok("-01"  !~ /^$r1$/);
ok(-10    =~ /^$r1$/);
ok("-010" !~ /^$r1$/);

$r1 = rangespec('-10..10', {no_leading_zeroes => 1});
ok(-11    !~ /^$r1$/);
ok(-10    =~ /^$r1$/);
ok("-010" !~ /^$r1$/);
ok(-9     =~ /^$r1$/);
ok("-09"  !~ /^$r1$/);
ok("-009" !~ /^$r1$/);
ok(-1     =~ /^$r1$/);
ok("-01"  !~ /^$r1$/);
ok("-001" !~ /^$r1$/);
ok(0      =~ /^$r1$/);
ok("00"   !~ /^$r1$/);
ok("000"  !~ /^$r1$/);
ok(1      =~ /^$r1$/);
ok("01"   !~ /^$r1$/);
ok("001"  !~ /^$r1$/);
ok(9      =~ /^$r1$/);
ok("09"   !~ /^$r1$/);
ok("009"  !~ /^$r1$/);
ok(10     =~ /^$r1$/);
ok("010"  !~ /^$r1$/);
ok(11     !~ /^$r1$/);
