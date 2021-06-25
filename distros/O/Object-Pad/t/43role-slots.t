#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole {
   has $one = 1;
   method one { $one }
}

class AClass does ARole {
   has $two = 2;
   method two { $two }
}

{
   my $obj = AClass->new;
   isa_ok( $obj, "AClass", '$obj' );

   is( $obj->one, 1, 'AClass has a ->one method' );
   is( $obj->two, 2, 'AClass has a ->two method' );
}

class BClass isa AClass {
   has $three = 3;
   method three { $three }
}

{
   my $obj = BClass->new;

   is( $obj->one,   1, 'BClass has a ->one method' );
   is( $obj->two,   2, 'BClass has a ->two method' );
   is( $obj->three, 3, 'BClass has a ->three method' );
}

done_testing;
