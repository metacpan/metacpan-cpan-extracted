#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use Regexp::Parsertron;

# ---------------------

my($re)		= qr/Perl|JavaScript/i;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

# Return 0 for success and 1 for failure.

my($result)		= $parser -> parse(re => $re);
my($node_id)	= 5; # Obtained from displaying and inspecting the tree.

say "Calling append(text => '|C++', uid => $node_id)";

$parser -> append(text => '|C++', uid => $node_id);
$parser -> print_raw_tree;
$parser -> print_cooked_tree;

my($as_string) = $parser -> as_string;

say "Original:    $re. Result: $result (0 is success)";
say "as_string(): $as_string";

$result = $parser -> validate;

say "validate():  Result: $result (0 is success)";

# Return 0 for success and 1 for failure.

$parser -> reset;
$parser -> verbose(0);

$re		= qr/Perl|JavaScript|(?:Flub|BCPL)/i;
$result	= $parser -> parse(re => $re);

say "\nAdd complexity to the regexp by parsing a new regexp: $re";

$parser -> print_raw_tree;
