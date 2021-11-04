#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

my $MATCH_ARGCOUNT =
   # Perl since 5.33.6 adds got-vs-expected counts to croak message
   $] >= 5.033006 ? qr/ \(got \d+; expected \d+\)/ : "";

class Colour {
   has $red   :reader            :writer;
   has $green :reader(get_green) :writer;
   has $blue  :mutator;
   has $white :accessor;

   BUILD {
      ( $red, $green, $blue, $white ) = @_;
   }

   method rgbw {
      ( $red, $green, $blue, $white );
   }
}

# readers
{
   my $col = Colour->new(50, 60, 70, 80);

   is( $col->red,       50, '$col->red' );
   is( $col->get_green, 60, '$col->get_green' );
   is( $col->blue,      70, '$col->blue' );
   is( $col->white,     80, '$col->white' );

   # Reader complains if given any arguments
   my $LINE = __LINE__+1;
   ok( !defined eval { $col->red(55); 1 },
      'reader method complains if given any arguments' );
   like( $@, qr/^Too many arguments for subroutine 'Colour::red'$MATCH_ARGCOUNT(?: at \S+ line $LINE\.)?$/,
      'exception message from too many arguments to reader' );

   class AllTheTypesReader {
      has @av :reader;
      has %hv :reader;
      ADJUST {
         @av = qw( one two three );
         %hv = (one => 1, two => 2);
      }
   }

   my $allthetypes = AllTheTypesReader->new;
   is_deeply( [ $allthetypes->av ], [qw( one two three )], ':reader on array slot' );
   is_deeply( { $allthetypes->hv }, { one => 1, two => 2 }, ':reader on hash slot' );

   is( scalar $allthetypes->av, 3, ':reader on array slot in scalar context' );

   # On perl 5.26 onwards this yields the number of keys; before that it
   # stringifies to something like "2/8" but that's not terribly reliable, so
   # don't bother testing that
   is( scalar $allthetypes->hv, 2, ':reader on hash slot in scalar context' ) if $] >= 5.028;
}

# writers
{
   my $col = Colour->new;

   $col->set_red( 80 );
   is( $col->set_green( 90 ), $col, '->set_* writer returns invocant' );
   $col->blue = 100;
   $col->white( 110 );

   is_deeply( [ $col->rgbw ], [ 80, 90, 100, 110 ],
      '$col->rgbw after writers' );

   # Writer complains if not given enough arguments
   my $LINE = __LINE__+1;
   ok( !defined eval { $col->set_red; 1 },
      'writer method complains if given no argument' );
   like( $@, qr/^Too few arguments for subroutine 'Colour::set_red'$MATCH_ARGCOUNT(?: at \S+ line $LINE\.)?$/,
      'exception message from too few arguments to writer' );

   class AllTheTypesWriter {
      has @av :writer;
      has %hv :writer;
      method test
      {
         Test::More::is_deeply( \@av, [qw( four five six )], ':writer on array slot' );
         Test::More::is_deeply( \%hv, { three => 3, four => 4 }, ':writer on hash slot' );
      }
   }

   my $allthetypes = AllTheTypesWriter->new;
   $allthetypes->set_av(qw( four five six ));
   $allthetypes->set_hv( three => 3, four => 4 );
   $allthetypes->test;
}

done_testing;
