#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   plan skip_all => "Syntax::Keyword::Dynamically is not available"
      unless eval { require Syntax::Keyword::Dynamically };
   plan skip_all => "Sentinel is not available"
      unless eval { require Sentinel };

   Syntax::Keyword::Dynamically->import;
   Sentinel->import;
}

my @get_values;
my @set_values;
sub accessor :lvalue
{
   sentinel get => sub { return shift @get_values },
            set => sub { push @set_values, $_[0] };
}

subtest "dynamically setting a Sentinel" => sub {
   @get_values = ( "saved", "inside", "restored" );

   {
      dynamically accessor = "new";
      is( accessor, "inside", 'value within scope' );
   }
   is( accessor, "restored", 'value restored after block leave' );
   is_deeply( \@set_values, [ "new", "saved" ], 'STORE magic invoked' );
};

done_testing;
