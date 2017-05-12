#!perl

# 10_rcx.t - Test RCX functionality

use Test::More tests => 3;
use strict;
use warnings;

my $prog = __FILE__;
$prog =~ s{[^/]+\.t}{../contrib/RCX.pl}x;
my $try = `$^X $prog`;
ok($try =~ /loaded/, "load");
ok($try =~ /drawn/, "compile");
ok($try =~ /dropped/, "method");
