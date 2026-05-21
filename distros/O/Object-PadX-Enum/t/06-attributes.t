#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::Pad 0.825;
use Object::PadX::Enum;

# Fixtures: plain Object::Pad classes and roles. Defined in BEGIN blocks so
# their packages (and $VERSION values) exist before later `enum` declarations
# in this file are compiled.
BEGIN {
   package TestBase;
   our $VERSION = '1.20';

   use Object::Pad;
   class TestBase {
      method greet { return 'hi from TestBase'; }
   }
}

BEGIN {
   package TestRole;
   our $VERSION = '0.50';

   use Object::Pad;
   role TestRole {
      method shout { return 'ROLE!'; }
   }
}

BEGIN {
   package TestRole2;

   use Object::Pad;
   role TestRole2 {
      method whisper { return 'role2'; }
   }
}

# :isa(BASE)
{
   enum Sub1 :isa(TestBase) {
      item A;
      item B;
   }
   ok( Sub1->A->isa('TestBase'),     ':isa makes the enum a subclass' );
   is( Sub1->A->greet, 'hi from TestBase', 'inherited method callable' );
   is( Sub1->A->ordinal, 0, 'ordinal still injected with :isa' );
}

# :extends synonym
{
   enum Sub2 :extends(TestBase) {
      item X;
   }
   ok( Sub2->X->isa('TestBase'), ':extends is a synonym for :isa' );
}

# :isa with VERSION (passing)
{
   enum Sub3 :isa(TestBase 1.0) {
      item Y;
   }
   ok( Sub3->Y->isa('TestBase'), ':isa(BASE VER) succeeds when VER is satisfied' );
}

# :isa with VERSION (failing)
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum SubBad :isa(TestBase 99.0) {
         item Z;
      }
      1;
   };
   ok( !$ok, ':isa(BASE BAD_VER) croaks' );
   like( $@, qr/version/i, 'error mentions version' );
}

# :does(ROLE)
{
   enum WithRole :does(TestRole) {
      item P;
   }
   is( WithRole->P->shout, 'ROLE!', ':does composes role method' );
}

# Multiple :does
{
   enum WithRoles :does(TestRole) :does(TestRole2) {
      item Q;
   }
   is( WithRoles->Q->shout,   'ROLE!', 'first  :does role method' );
   is( WithRoles->Q->whisper, 'role2', 'second :does role method' );
}

# :isa + :does combined
{
   enum Combined :isa(TestBase) :does(TestRole) {
      item R;
   }
   ok( Combined->R->isa('TestBase'), 'combined :isa works' );
   is( Combined->R->shout, 'ROLE!',  'combined :does works' );
   is( Combined->R->greet, 'hi from TestBase', 'inherited method works' );
}

# :abstract is rejected with semantic message.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Abstr :abstract {
         item A;
      }
      1;
   };
   ok( !$ok, ':abstract rejected' );
   like( $@, qr/abstract/i,   'message mentions abstract' );
   like( $@, qr/singleton/i,  'message explains singleton conflict' );
}

# :strict is rejected as unsupported.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Strict1 :strict(params) {
         item A;
      }
      1;
   };
   ok( !$ok, ':strict rejected' );
   like( $@, qr/strict/i, 'message mentions strict' );
}

# :repr is rejected as unsupported.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Repr1 :repr(keys) {
         item A;
      }
      1;
   };
   ok( !$ok, ':repr rejected' );
   like( $@, qr/repr/i, 'message mentions repr' );
}

# Unknown attribute is rejected.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Bogus :bogus {
         item A;
      }
      1;
   };
   ok( !$ok, 'unknown attribute rejected' );
   like( $@, qr/bogus/i, 'message names the offending attribute' );
}

# Unknown superclass is reported clearly.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum NoSuch :isa(No::Such::Package::Ever) {
         item A;
      }
      1;
   };
   ok( !$ok, ':isa with missing package rejected' );
   like( $@, qr/No::Such::Package::Ever/, 'error names the missing package' );
}

# Double :isa is rejected.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Double :isa(TestBase) :isa(TestBase) {
         item A;
      }
      1;
   };
   ok( !$ok, 'double :isa rejected' );
   like( $@, qr/Multiple/i, 'message mentions multiple' );
}

done_testing;
