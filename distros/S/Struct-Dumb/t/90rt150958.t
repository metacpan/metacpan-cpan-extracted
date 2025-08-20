#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Scalar::Util qw( refaddr );

use Struct::Dumb;

# Check that we can use field names that aren't valid as Perl identifiers

# positional
{
   struct WithDot => [qw( bla.foo )];

   my $val = WithDot( "the value" );

   my $meth = "bla.foo";
   is( $val->$meth, "the value", 'Accessor of instance created with positional constructor' );
}

# leading digits in field names
{
   struct WithDigit => [qw( 1 2 3 )];

   my $val = WithDigit( 4, 5, 6 );

   my $meth = "1";
   is( $val->$meth, 4, 'Accessor of instance with single-digit field names' );
}

# quote symbols in field names
{
   struct WithQuotes => [qw( abc "abc" )];

   my $val = WithQuotes( "first", "second" );

   my $meth = q("abc");
   is( $val->$meth, "second", 'Accessor of instance with quotes on field names' );
}

# named
{
   struct WithDotNamed => [qw( bla.foo )], named_constructor => 1;

   my $val = WithDotNamed( 'bla.foo' => "the value" );

   my $meth = "bla.foo";
   is( $val->$meth, "the value", 'Accessor of instance created with named constructor' );
}

done_testing;
