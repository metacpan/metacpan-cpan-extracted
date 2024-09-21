#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(init_expr)';

# initexprs can capture regular class-level lexicals
{
   class SerialNumbered {
      my $next_seq = 1;
      field $seq :reader = $next_seq++;
   }

   is( SerialNumbered->new->seq, 1, 'first instance 1' );
   is( SerialNumbered->new->seq, 2, 'second instance 2' );
}

# state works correctly inside them
{
   class SerialNumberedByState {
      field $seq :reader { state $next = 1; $next++ }
   }

   is( SerialNumberedByState->new->seq, 1, 'first instance 1 by state' );
   is( SerialNumberedByState->new->seq, 2, 'second instance 2 by state' );
}

# initexprs run in declared order
{
   my @inited;
   class WithThreeFields {
      field $x { push @inited, "x" }
      field $y { push @inited, "y" }
      field $z { push @inited, "z" }
   }

   WithThreeFields->new;
   is( \@inited, [qw( x y z )], 'initexprs run in declared order' );
}

# :param overrides initexpr
{
   my %init_called;
   class WithParams {
      field $one :param :reader { $init_called{one} = 1 }
      field $two :param :reader { $init_called{two} = 2 }
   }

   my $obj = WithParams->new( one => 11 );

   is( $obj->one, 11, ':param overrode initexpr' );
   ok( !exists $init_called{one}, ':param stopped initexpr running' );

   is( $obj->two, 2, 'unpassed :param still used initexpr' );
   is( $init_called{two}, 2, 'unpassed :param still ran initexpr' );
}

# field initexprs can see earlier fields
{
   class FieldsSeeFields {
      field $one   :param;
      field $two           = 2;
      field $three :reader = $one + $two;
   }

   is( FieldsSeeFields->new( one => 1 )->three, 3, 'field initialised from fields' );
}

done_testing;
