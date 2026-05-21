#!perl
use v5.22;
use warnings;

use Test2::V0;

# String-eval contains its own compilation unit; UNITCHECK fires at end of
# eval-compile, runtime follows inside the eval. Singletons should be usable
# from the same eval immediately after the enum block.
{
   my $ord = eval q{
      use Object::PadX::Enum;
      enum InEval {
         item A;
         item B;
      }
      InEval->B->ordinal;
   };
   ok( !$@, 'no eval error' ) or diag $@;
   is( $ord, 1, 'eval-string enum: InEval->B->ordinal' );
}

# do BLOCK runs at runtime within the enclosing unit, after that unit's
# UNITCHECK. The item/finalize ops execute when the block runs.
use Object::PadX::Enum;

my $result = do {
   enum InDo {
      item X;
      item Y;
      item Z;
   }
   [ map { $_->ordinal } InDo->values ];
};

is( $result, [ 0, 1, 2 ], 'do BLOCK enum: ordinals in order' );

done_testing;
