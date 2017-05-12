#!/usr/bin/perl

use strict;
use warnings;

use B;
sub unqq($) { return B::perlstring( $_[0] ) }

use Test::More;

use Term::VTerm;

my $vt = Term::VTerm->new( cols => 80, rows => 25 );
$vt->set_utf8( 1 );

# State layer needs to just exist
$vt->obtain_state;

# mouse button
{
   # First enable mouse button mode
   $vt->input_write( "\e[?1000h" );

   $vt->mouse_button( 1, 1 );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 6, '->output_read after mouse button' );
   is( unqq $buf, unqq "\e[M\x20\x21\x21", '$buf from output_read' );

   $vt->mouse_button( 1, 0 );
   $vt->output_read( $buf, 128 );
   is( unqq $buf, unqq "\e[M\x23\x21\x21", '$buf from output_read after button release' );
}

# mouse movement
{
   $vt->input_write( "\e[?1003h" );

   $vt->mouse_move( 10, 20 );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 6, '->output_read after mouse move in movement mode' );
   is( unqq $buf, unqq "\e[M\x43\x35\x2b", '$buf from output_read after mouse move' );
}

done_testing;
