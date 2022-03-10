#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Inplace;

# valid targets
{
   my $str = "hello";
   inplace uc $str;
   is( $str, "HELLO", 'inplace uc on lexvar' );

   our $VAR = "package";
   inplace uc $VAR;
   is( $VAR, "PACKAGE", 'inplace uc on pkgvar' );

   my %hash = ( key => "value" );
   inplace uc $hash{key};
   is( $hash{key}, "VALUE", 'inplace uc on helem' );

   my @array = ( "elem" );
   inplace uc $array[0];
   is( $array[0], "ELEM", 'inplace uc on aelem' );
}

# banned targets
{
   # All these should fail to compile so we'll have to string-eval() them
   my @targets = (
      'lc $var',
   );

   my $var;

   foreach my $target ( @targets ) {
      ok( defined( my $err = defined eval( "inplace uc $target" ) ? undef : $@ ),
         "target '$target' fails" );
      like( $err, qr/^Cannot use \S+ as an argument to an inplace operator at / );
   }
}

done_testing;
