#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::LineNumber qw(
                             linenum
                     );

my $str = "a\nb\n\n d\n0";
is(linenum($str),
   "   1|a\n   2|b\n    |\n   4| d\n   5|0", "linenum 1");
is(linenum($str, {width=>2}),
   " 1|a\n 2|b\n  |\n 4| d\n 5|0", "linenum opt:width");
is(linenum($str, {zeropad=>1}),
   "0001|a\n0002|b\n    |\n0004| d\n0005|0", "linenum opt:zeropad");
is(linenum($str, {skip_empty=>0}),
   "   1|a\n   2|b\n   3|\n   4| d\n   5|0", "linenum opt:skip_empty");

DONE_TESTING:
done_testing();
