#!/usr/bin/perl

use lib 'lib', '../lib';

use Time::HiRes;
use POSIX::strftime::GNU;
use POSIX qw( strftime locale_h );

setlocale(LC_TIME, 'C');

my ($t, $nsec) = Time::HiRes::gettimeofday;
my @t = localtime $t;
$t[0] += $nsec / 10e5;

print strftime('%Y-%m-%dT%H:%M:%S,%N%z', @t), "\n";
