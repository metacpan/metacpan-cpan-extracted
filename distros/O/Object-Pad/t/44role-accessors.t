#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

role ARole {
   field $one :reader = 1;
}

class AClass {
   apply ARole;
}

# RT136507
{
   my $obj = AClass->new;
   is( $obj->one, 1, '$obj->one is visible' );
}

role BRole {
   field $data :reader :param;
}

class BClass {
   apply BRole;
}

{
   my $obj = BClass->new( data => 123 );
   is( $obj->data, 123, 'BClass constructor takes role params' );
}

done_testing;
