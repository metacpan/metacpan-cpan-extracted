#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad;

class Example {
   method m { }
}

my $classmeta = Example->META;

my $methodmeta = $classmeta->get_own_method( 'm' );

is( $methodmeta->name, "m", '$methodmeta->name' );
is( $methodmeta->class->name, "Example", '$methodmeta->class gives class' );

done_testing;
