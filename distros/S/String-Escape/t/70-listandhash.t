#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 5 }

use String::Escape qw( list2string string2list hash2string string2hash );

###

ok( list2string('hello', 'I move next march') eq 'hello "I move next march"' );

ok( ( string2list('one "second item" 3 "four\nlines\nof\ntext"') )[1] eq 'second item' );

###

ok( hash2string( 'foo' => 'Animal Cities', 'bar' => 'Cheap' ) eq 'foo="Animal Cities" bar=Cheap' );

my %hash = string2hash('key=value "undefined key" words="the cat in the hat"');

ok( $hash{'words'} eq 'the cat in the hat' );

ok( exists $hash{'undefined key'} and ! defined $hash{'undefined key'} );
