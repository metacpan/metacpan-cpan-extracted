#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;

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

role CRole does ARole
{
   has $three = 3;
   method three { $three }
}

class CClass does CRole {}

# role slots via composition
{
   my $obj = CClass->new;

   is( $obj->one,   1, 'CClass has a ->one method' );
   is( $obj->three, 3, 'CClass has a ->three method' );
}

# diamond inheritence scenario
{
   role DRole {
      has $slot = 1;
      ADJUST { $slot++ }
      method slot { $slot }
   }

   role D1Role does DRole {}
   role D2Role does DRole {}

   role DxRole does D1Role, D2Role {}

   class DClass does D1Role, D2Role {}

   my $obj1 = DClass->new;
   is( $obj1->slot, 2, 'DClass->slot is 2 via diamond' );

   class DxClass does DxRole {}

   my $obj2 = DxClass->new;
   is( $obj2->slot, 2, 'DxClass->slot is 2 via diamond' );
}

# RT139665
{
   my $arr = [];

   role WithWeakRole {
      has $slot :param :weak;
   }

   class implWithWeak does WithWeakRole {}

   my $obj = implWithWeak->new( slot => $arr );
   is_oneref( $arr, '$arr has one reference after implWithWeak constructor' );
}

done_testing;
