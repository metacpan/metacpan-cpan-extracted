#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result)		= $parser -> parse(re => $re);
my($node_id)	= 5; # Obtained from displaying and inspecting the tree.

print "Calling append(text => '|C++', uid => $node_id) \n";

$parser -> append(text => '|C++', uid => $node_id);
$parser -> print_raw_tree;
$parser -> print_cooked_tree;

my($as_string) = $parser -> as_string;

print "Original:    $re. Result: $result (0 is success) \n";
print "as_string(): $as_string \n";

$result = $parser -> validate;

print "validate():  Result: $result (0 is success) \n";

# Return 0 for success and 1 for failure.

$parser -> reset;
$parser -> verbose(0);

$re		= qr/Perl|JavaScript|(?:Flub|BCPL)/i;
$result	= $parser -> parse(re => $re);

print "\nAdd complexity to the regexp by parsing a new regexp: $re \n";

$parser -> print_raw_tree;
