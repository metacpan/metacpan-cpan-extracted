#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

# Compile-time error: item outside enum.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      item NOPE;
      1;
   };
   ok( !$ok, 'item outside enum is a compile error' );
   like( $@, qr/item/, 'error message mentions item' );
}

# Runtime error: duplicate item name.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Dup {
         item SAME;
         item SAME;
      }
      1;
   };
   ok( !$ok, 'duplicate item names croak' );
   like( $@, qr/Duplicate item 'SAME'/, 'duplicate error mentions name' );
}

# Runtime error: reserved item name.
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum Reserved {
         item values;
      }
      1;
   };
   ok( !$ok, 'reserved name "values" rejected' );
   like( $@, qr/reserved/, 'reserved error message' );
}

# Runtime error: reserved item name "name".
{
   my $ok = eval q{
      use Object::PadX::Enum;
      enum ReservedName {
         item name;
      }
      1;
   };
   ok( !$ok, 'reserved name "name" rejected' );
   like( $@, qr/reserved/, 'reserved error message for name' );
}

# Compile-time error: item outside enum, without `use` in eval (hint key gates it).
{
   my $ok = eval q{
      item LOOSE;
      1;
   };
   ok( !$ok, 'item with no hint key is a syntax error' );
}

done_testing;
