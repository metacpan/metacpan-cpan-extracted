#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;

plan tests => 4;


use lib 'lib';

use Parse::Gnaw;
use Parse::Gnaw::LinkedList;



# simple rules test. Only using 'lit' matches because 
# we're just testing basic construction and basic parsing match/no match behavior.

rule('a_then_b', 'a', 'b');
rule('A_then_Z', 'A', 'Z');

my $ab_string;


$ab_string=Parse::Gnaw::LinkedList->new('abcd');
ok($ab_string->parse($a_then_b), "should found a then b rule in abcd string");


$ab_string=Parse::Gnaw::LinkedList->new('abcd');
ok(not($ab_string->parse($A_then_Z)), "should not find A then Z rule in abcd string");


# repeat the tests so we can see parse match then not match then match again.

$ab_string=Parse::Gnaw::LinkedList->new('abcd');
ok($ab_string->parse($a_then_b), "should find a then b rule in abcd string");

$ab_string=Parse::Gnaw::LinkedList->new('abcd');
ok(not($ab_string->parse($A_then_Z)), "should not find A then A rule in abcd string");

__DATA__

This is trying to show how the code would look for creating rules.

A rule is just a package array. But to reduce the amount of typing,
we declare it inside the "rule" subroutine imported from Parse::Gnaw.
This allows us to pass in literals like 'a', and translate them into
something more machine friendly, like [ \&lit, 'a', 'lit', blah]

rule1 should translate into the exact same thing as this:

our @rule1 = (
	lit('a'),
	lit('b'),
);

But by using "rule", we don't have to put "lit" in front of everything.
Instead, we can write the literal characters as strings, and have the
"rule" subroutine check for strings and pack them as needed.





