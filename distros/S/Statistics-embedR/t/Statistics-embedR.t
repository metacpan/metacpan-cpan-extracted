#!perl -T

use 5.010;
use warnings;
use strict;
use Statistics::embedR;
use Test::More tests => 6;

my $r = Statistics::embedR->new;

is $r->R("1"), 1, "R() can return a integer scalar.";
is $r->R('"1"'), "1", "R() can return a string scalar.";
is_deeply $r->R("a <- 1:3", "a"), [1, 2, 3], "R() works with a list of statements, and can return a ARRAY ref.";

my $ary = [3,5,7];
$r->arry2R($ary, "array");
is_deeply $r->R("array"), $ary, "arry2R() works.";

is $r->sum("c(2,3)"), 5, "AUTOLOAD() works.";
is_deeply $r->as_numeric('c("1", "2")'), [1, 2], "AUTOLOAD() automatically convert _ to .";

# vim: sw=4 ts=4 ft=perl expandtab
