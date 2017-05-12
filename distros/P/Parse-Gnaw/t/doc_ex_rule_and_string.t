#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use Test::More;

plan tests => 2;

use lib 'lib';
use Parse::Gnaw;
use Parse::Gnaw::LinkedListDimensions1;

# A Simple Rule Example
rule( 'rule1', 'H', 'I' );

# A simple string example
my $histring=Parse::Gnaw::LinkedListDimensions1->new("HI THERE");

ok($histring->parse('rule1'), "This is like regex   'HI THERE' =~ m/HI/ ");

my $lostring=Parse::Gnaw::LinkedListDimensions1->new("LO THERE");
ok(not($lostring->parse('rule1')), "This is like regex   'LO THERE' =~ m/HI/ ");

