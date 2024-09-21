#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Object::Pad 0.800;

role ARole {
   field $one = 1;
   method one { $one }
}

class AClass {
   apply ARole;

   field $two = 2;
   method two { $two }
}

{
   my $obj = AClass->new;
   isa_ok( $obj, [ "AClass" ], '$obj' );

   is( $obj->one, 1, 'AClass has a ->one method' );
   is( $obj->two, 2, 'AClass has a ->two method' );
}

class AClassLate {
   field $two = 2;
   method two { $two }

   apply ARole;
}

{
   my $obj = AClassLate->new;
   isa_ok( $obj, [ "AClassLate" ], '$obj' );

   is( $obj->one, 1, 'AClassLate has a ->one method' );
   is( $obj->two, 2, 'AClassLate has a ->two method' );
}

class BClass {
   inherit AClass;

   field $three = 3;
   method three { $three }
}

{
   my $obj = BClass->new;

   is( $obj->one,   1, 'BClass has a ->one method' );
   is( $obj->two,   2, 'BClass has a ->two method' );
   is( $obj->three, 3, 'BClass has a ->three method' );
}

role CRole {
   apply ARole;

   field $three = 3;
   method three { $three }
}

class CClass {
   apply CRole;
}

# role fields via composition
{
   my $obj = CClass->new;

   is( $obj->one,   1, 'CClass has a ->one method' );
   is( $obj->three, 3, 'CClass has a ->three method' );
}

# diamond inheritence scenario
{
   role DRole {
      field $field = 1;
      ADJUST { $field++ }
      method field { $field }
   }

   role D1Role { apply DRole; }
   role D2Role { apply DRole; }

   role DxRole { apply D1Role; apply D2Role; }

   class DClass { apply D1Role; apply D2Role; }

   my $obj1 = DClass->new;
   is( $obj1->field, 2, 'DClass->field is 2 via diamond' );

   class DxClass { apply DxRole; }

   my $obj2 = DxClass->new;
   is( $obj2->field, 2, 'DxClass->field is 2 via diamond' );
}

# RT139665
{
   my $arr = [];

   role WithWeakRole {
      field $field :param :weak;
   }

   class implWithWeak { apply WithWeakRole; }

   my $obj = implWithWeak->new( field => $arr );
   is_oneref( $arr, '$arr has one reference after implWithWeak constructor' );
}

done_testing;
