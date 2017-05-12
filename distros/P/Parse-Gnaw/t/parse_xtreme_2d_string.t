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
use Parse::Gnaw::LinkedListDimensions2;
use Parse::Gnaw::LinkedListConstants;
use Parse::Gnaw::Blocks::Letter;
use Parse::Gnaw::Blocks::LetterConstants;


rule('abgl', 'a','b','g','l');
rule('abcl', 'a','b','c','l');
rule('afkp', 'a','f','k','p');
rule('afki', 'a','f','k','i');


# we're going to construct a basic 2-dimensional string linked list to parse
# but we're not going to run a grammar on it.
# we're just going to see that the 2D linked list got created correctly.

my $raw_2d_string=<<'RAWSTRING';
abcd
efgh
ijkl
mnop
RAWSTRING

my $string1=Parse::Gnaw::LinkedListDimensions2->new(string=>$raw_2d_string);
my $string2=Parse::Gnaw::LinkedListDimensions2->new(string=>$raw_2d_string);
my $string3=Parse::Gnaw::LinkedListDimensions2->new(string=>$raw_2d_string);
my $string4=Parse::Gnaw::LinkedListDimensions2->new(string=>$raw_2d_string);



ok(    $string1->parse('abgl'),   "parse 2d string with abgl rule");
ok(not($string2->parse('abcl')),  "parse 2d string with abcl rule");
ok(    $string3->parse('afkp'),   "parse 2d string with afkp rule");
ok(not($string4->parse('afki')),  "parse 2d string with afki rule");

__DATA__

