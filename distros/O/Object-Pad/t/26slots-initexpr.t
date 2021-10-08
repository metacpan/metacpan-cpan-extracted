#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

# initexprs can capture regular class-level lexicals
{
   class SerialNumbered {
      my $next_seq = 1;
      has $seq :reader { $next_seq++ };
   }

   is( SerialNumbered->new->seq, 1, 'first instance 1' );
   is( SerialNumbered->new->seq, 2, 'second instance 2' );
}

# state works correctly inside them
{
   class SerialNumberedByState {
      has $seq :reader { state $next = 1; $next++ }
   }

   is( SerialNumberedByState->new->seq, 1, 'first instance 1 by state' );
   is( SerialNumberedByState->new->seq, 2, 'second instance 2 by state' );
}

# initexprs run in declared order
{
   my @inited;
   class WithThreeSlots {
      has $x { push @inited, "x" };
      has $y { push @inited, "y" };
      has $z { push @inited, "z" };
   }

   WithThreeSlots->new;
   is_deeply( \@inited, [qw( x y z )], 'initexprs run in declared order' );
}

# :param overrides initexpr
{
   my %init_called;
   class WithParams {
      has $one :param :reader { $init_called{one} = 1 };
      has $two :param :reader { $init_called{two} = 2 };
   }

   my $obj = WithParams->new( one => 11 );

   is( $obj->one, 11, ':param overrode initexpr' );
   ok( !exists $init_called{one}, ':param stopped initexpr running' );

   is( $obj->two, 2, 'unpassed :param still used initexpr' );
   is( $init_called{two}, 2, 'unpassed :param still ran initexpr' );
}

done_testing;
