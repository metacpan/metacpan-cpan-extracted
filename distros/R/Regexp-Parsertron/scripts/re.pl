#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/^[+]([^(]+)$/mi;
my($parser)	= Regexp::Parsertron -> new(verbose => 2);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

#$parser -> raw_tree;
#$parser -> cooked_tree;

my($as_string)	= $parser -> as_string;
my($as_re)		= $parser -> as_re;

print "Original:  $re. Result: $result. (0 is success)\n";
print "as_string: $as_string\n";
print "as_re:     $as_re\n";
print 'Perl error count:  ', $parser -> perl_error_count, "\n";
print 'Marpa error count: ', $parser -> marpa_error_count, "\n";
