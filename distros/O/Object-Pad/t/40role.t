#!/usr/bin/perl

use v5.18;
use warnings;
use utf8;

use Test2::V0;

use Object::Pad 0.800;

role ARole {
   method one { return 1 }

   method own_cvname {
      return +(caller(0))[3];
   }
}

class AClass {
   apply ARole;
}

{
   my $obj = AClass->new;
   isa_ok( $obj, [ "AClass" ], '$obj' );

   is( $obj->one, 1, 'AClass has a ->one method' );
   is( $obj->own_cvname, "AClass::own_cvname", '->own_cvname sees correct subname' );
}

is( (class { apply ARole })->new->one, 1,
   'anonymous classes can apply roles' );

# Older :does attribute notation
class AClassAttr :does(ARole) {
}

{
   my $obj = AClassAttr->new;
   isa_ok( $obj, [ "AClassAttr" ], '$obj' );

   is( $obj->one, 1, 'AClassAttr has a ->one method' );
   is( $obj->own_cvname, "AClassAttr::own_cvname", '->own_cvname sees correct subname' );
}

role BRole {
   method two { return 2 }
}

class BClass {
   apply ARole;
   apply BRole;
}

{
   my $obj = BClass->new;

   is( $obj->one, 1, 'BClass has a ->one method' );
   is( $obj->two, 2, 'BClass has a ->two method' );
   is( $obj->own_cvname, "BClass::own_cvname", '->own_cvname sees correct subname' );
}

role CRole {
   method three;
}

class CClass {
   apply CRole;

   method three { return 3 }
}

pass( 'CClass compiled OK' );

# Because we store embedding info in the pad of a method CV, we should check
# that recursion and hence CvDEPTH > 1 works fine
{
   role RecurseRole {
      method recurse {
         my ( $x ) = @_;
         return $x ? $self->recurse( $x - 1 ) + 1 : 0;
      }
   }

   class RecurseClass { apply RecurseRole }

   is( RecurseClass->new->recurse( 5 ), 5, 'role methods can be reëntrant' );
}

role DRole {
   apply BRole;

   method four { return 4 }
}

class DClass {
   apply DRole;
}

{
   my $obj = DClass->new;

   is( $obj->four, 4, 'DClass has DRole method' );
   is( $obj->two,  2, 'DClass inherited BRole method' );
}

role ERole {
   apply ARole;
   apply BRole;
}

class EClass {
   apply ERole;
}

{
   my $obj = EClass->new;

   is( $obj->one, 1, 'EClass has a ->one method' );
   is( $obj->two, 2, 'EClass has a ->two method' );
}

role FRole {
   method onetwothree :common { 123 }
}

class FClass {
   apply FRole;
}

{
   is( FClass->onetwothree, 123, 'FClass has a :common ->onetwothree method' );
}

# Perl #19676
#   https://github.com/Perl/perl5/issues/19676

role GRole {
   method a { pack "C", 65 }
}

class GClass {
   apply GRole;
}

{
   is( GClass->new->a, "A", 'GClass ->a method has constant' );
}

done_testing;
