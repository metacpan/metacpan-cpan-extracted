#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

print "Original:  $re. Result: $result. (0 is success). \n";
