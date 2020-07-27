#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try qw( try :experimental );

sub func
{
   my ( $ret, $except ) = @_;

   try {
      die $except if $except;
      return "ret => $ret";
   }
   catch ($e isa X) {
      return "X => [@$e]";
   }
   catch ($e =~ m/^Cannot /) {
      chomp $e;
      return "cannot => $e";
   }
   catch ($e) {
      return "default => $e";
   }
}

is( func( 123 ), "ret => 123", 'typed catch succeeds' );

is( func( 0, "failure\n" ), "default => failure\n",
   'typed catch default case' );
is( func( 0, bless [45], "X" ), "X => [45]",
   'typed catch isa case' );
is( func( 0, "Cannot do X\n" ), "cannot => Cannot do X",
   'typed catch regexp case' );

sub fallthrough
{
   my ( $except ) = @_;

   try {
      die $except;
   }
   catch ($e isa X) {
      return "X => [@$e]";
   }
   # no default
}

is( fallthrough( bless ["OK"], "X" ), "X => [OK]",
   'typed catch not fallthrough' );
is( eval { fallthrough( "Oopsie\n" ); 1 } ? undef : $@, "Oopsie\n",
   'typed catch fallthrough' );

done_testing;
