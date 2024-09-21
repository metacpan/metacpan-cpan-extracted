#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Object::Pad 0.800;

class Point {
   BUILD { @$self = @_; }

   method where { sprintf "(%d,%d)", @$self }

   method classname { return __CLASS__ }
}

{
   my $p = Point->new( 10, 20 );
   is_oneref( $p, '$p has refcount 1 initially' );

   is( $p->where, "(10,20)", '$p->where' );
   is_oneref( $p, '$p has refcount 1 after method' );

   is( $p->classname, "Point", '__CLASS__ inside method' );
}

# anon methods
{
   class Point3 {
      BUILD { @$self = @_; }

      our $clearer = method {
         @$self = ( 0 ) x 3;
      };
   }

   my $p = Point3->new( 1, 2, 3 );
   $p->$Point3::clearer();

   is( [ @$p ], [ 0, 0, 0 ],
      'anon method' );
}

# nested anon method (RT132321)
SKIP: {
   skip "This causes SEGV on perl 5.16 (RT132321)", 1 if $] lt "5.018";
   class RT132321 {
      field $_genvalue;

      BUILD {
         $_genvalue = method { 123 };
      }

      method value { $self->$_genvalue() }
   }

   my $obj = RT132321->new;
   is( $obj->value, 123, '$obj->value from BUILD-generated anon method' );
}

# method warns about redeclared $self (RT132428)
{
   class RT132428 {
      BEGIN {
         my $warnings = "";
         local $SIG{__WARN__} = sub { $warnings .= join "", @_; };

         ::ok( defined eval <<'EOPERL',
            method test {
               my $self = shift;
            }
            1;
EOPERL
            'method compiles OK' );

         ::like( $warnings,
            qr/^"my" variable \$self masks earlier declaration in same scope at \(eval \d+\) line 2\./,
            'warning from redeclared $self comes from correct line' );
      }
   }
}

done_testing;
