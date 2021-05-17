#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   has $one :reader = 1;
}

class AClass implements ARole {
}

# RT136507
{
   my $obj = AClass->new;
   is( $obj->one, 1, '$obj->one is visible' );
}

done_testing;
