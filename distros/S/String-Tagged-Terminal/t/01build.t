#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged::Terminal;

# A handy function for making test output a little neater
use B qw( perlstring );
sub is_unqq
{
   my ( $got, $want, $name ) = @_;

   my $builder = Test::Builder->new;
   return $builder->is_eq( perlstring( $got ), perlstring( $want ), $name );
}

# unformatted
{
   my $st = String::Tagged::Terminal->new
      ->append( "Hello, world!" );

   is( $st->build_terminal, "Hello, world!",
      '->build_terminal on unformatted' );
}

# simple boolean attribute formatting
{
   my $st = String::Tagged::Terminal->new
      ->append( "A " )
      ->append_tagged( "bold", bold => 1 )
      ->append( " string" );

   is_unqq( $st->build_terminal, "A \e[1mbold\e[m string",
      '->build_terminal on bold' );

   $st = String::Tagged::Terminal->new
      ->append( "An " )
      ->append_tagged( "underlined", under => 1 )
      ->append( " string" );

   is_unqq( $st->build_terminal, "An \e[4munderlined\e[m string",
      '->build_terminal on under' );
}

# Altfont attribute
{
   my $st = String::Tagged::Terminal->new
      ->append( "Some " )
      ->append_tagged( "fixedwidth", altfont => 1 )
      ->append( " and " )
      ->append_tagged( "fancy", altfont => 2 )
      ->append( " formatting" );

   is_unqq( $st->build_terminal, "Some \e[11mfixedwidth\e[m and \e[12mfancy\e[m formatting",
      '->build_terminal on altfont' );
}

# Colours
{
   my $st = String::Tagged::Terminal->new
      ->append( "With " )
      ->append_tagged( "colour", fgindex => 1 );

   is_unqq( $st->build_terminal, "With \e[31mcolour\e[m",
      '->build_terminal on VGA8 colour' );

   $st = String::Tagged::Terminal->new
      ->append( "With " )
      ->append_tagged( "hi-colour", fgindex => 10 );

   is_unqq( $st->build_terminal, "With \e[92mhi-colour\e[m",
      '->build_terminal on Hi16 colour' );

   $st = String::Tagged::Terminal->new
      ->append( "With " )
      ->append_tagged( "palette colour", fgindex => 50 );

   is_unqq( $st->build_terminal, "With \e[38:5:50mpalette colour\e[m",
      '->build_terminal on Hi16 colour' );
}

# Trailing format gets reset
{
   my $st = String::Tagged::Terminal->new
      ->append( "Has trailing " )
      ->append_tagged( "formatting", italic => 1 );

   is_unqq( $st->build_terminal, "Has trailing \e[3mformatting\e[m",
      'Trailing formatting is reset' );
}

# Neighbouring colours can be swapped
{
   my $st = String::Tagged::Terminal->new
      ->append_tagged( "R", fgindex => 1 )
      ->append_tagged( "G", fgindex => 2 )
      ->append_tagged( "B", fgindex => 4 );

   is_unqq( $st->build_terminal, "\e[31mR\e[32mG\e[34mB\e[m",
      'Neighbouring colour tags behave' );
}

# no_color
{
   my $st = String::Tagged::Terminal->new( "abcde" );
   $st->apply_tag( 0, 3, under => 1 );
   $st->apply_tag( 2, 3, fgindex => 2 );

   is_unqq( $st->build_terminal( no_color => 1 ), "\e[4mabc\e[mde",
      'no_color option surpresses fgindex but not under' );
}

done_testing;
