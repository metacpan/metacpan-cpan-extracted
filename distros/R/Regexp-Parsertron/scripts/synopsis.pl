#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result) = $parser -> parse(re => $re);

print "Calling add(text => '|C++', uid => 6)\n";

$parser -> add(text => '|C++', uid => 6);
$parser -> raw_tree;
$parser -> cooked_tree;

my($as_string)	= $parser -> as_string;
my($as_re)		= $parser -> as_re;

print "Original:  $re. Result: $result. (0 is success)\n";
print "as_string: $as_string\n";
print "as_re:     $as_re\n";
print 'Perl error count:  ', $parser -> perl_error_count, "\n";
print 'Marpa error count: ', $parser -> marpa_error_count, "\n";

my($target) = 'C++';

if ($target =~ $as_re)
{
	print "Matches $target (without using \\Q...\\E)\n";
}
else
{
	print "Doesn't match $target\n";
}
