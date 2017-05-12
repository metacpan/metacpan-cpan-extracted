#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged::IRC;
String::Tagged->VERSION( '0.10' ); # chaining ->append_tagged

use Convert::Color::RGB8;

use B qw( perlstring );
sub unqq($) { perlstring @_ }

# unformatted
{
   my $st = String::Tagged::IRC->new
      ->append( "Hello, world!" );

   is( $st->build_irc, "Hello, world!", '->build on unformatted text' );
}

# boolean formatting
{
   my $st = String::Tagged::IRC->new
      ->append       ( "A word in " )
      ->append_tagged( "bold", bold => 1 )
      ->append       ( " or " )
      ->append_tagged( "italic", italic => 1 );

   is( unqq $st->build_irc, unqq "A word in \cBbold\cB or \c]italic", '->build with boolean formatting' );
}

# colour formatting
#  - test that it converts RGB8 instances
{
   my $st = String::Tagged::IRC->new
      ->append       ( "Something " )
      ->append_tagged( "red", fg => Convert::Color::RGB8->new( "ff0000" ) )
      ->append       ( " and " )
      ->append_tagged( "green", bg => Convert::Color::RGB8->new( "00ff00" ) );

   is( unqq $st->build_irc, unqq "Something \cC04red\cC and \cC00,09green\cC", '->build with indexed colours' );
}

done_testing;
