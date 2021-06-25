#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   has $one :reader = 1;
}

class AClass does ARole {
}

# RT136507
{
   my $obj = AClass->new;
   is( $obj->one, 1, '$obj->one is visible' );
}

role BRole {
   has $data :reader :param;
}

class BClass does BRole {
}

{
   my $obj = BClass->new( data => 123 );
   is( $obj->data, 123, 'BClass constructor takes role params' );
}

done_testing;
