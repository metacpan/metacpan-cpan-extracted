#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Dynamically;

my @fetched_values;
my @stored_values;

package TestScalar {
   sub TIESCALAR { bless [], shift }
   sub FETCH { return shift @fetched_values }
   sub STORE { push @stored_values, $_[1] }
}

tie my $scalar, "TestScalar";

subtest "tied scalar" => sub {
   @fetched_values = ( "saved", "inside", "restored" );

   {
      dynamically $scalar = "new";
      is( $scalar, "inside", 'new value within scope' );
   }
   is( $scalar, "restored", 'value restored after block leave' );
   is_deeply( \@stored_values, [ "new", "saved" ], 'STORE magic invoked' );
};

done_testing;
