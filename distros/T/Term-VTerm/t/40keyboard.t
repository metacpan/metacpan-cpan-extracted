#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Term::VTerm;

my $vt = Term::VTerm->new( cols => 80, rows => 25 );
$vt->set_utf8( 1 );

# Symbolic keys require state
$vt->obtain_state;

# idle
{
   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 0, '->output_read while idle' );
}

# ascii
{
   $vt->keyboard_unichar( ord "A" );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 1, '->output_read after keyboard push unichar' );
   is( $buf, "A", '$buf from output_read' );
}

# modified ascii
{
   use Term::VTerm qw( :mod );

   $vt->keyboard_unichar( ord "c", MOD_CTRL );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 1, '->output_read after keyboard push unichar modified' );
   is( $buf, chr 0x03, '$buf from output_read' );
}

# unicode
{
   $vt->keyboard_unichar( ord "é" );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 2, '->output_read after keyboard push unichar high' );
   is( $buf, do { no utf8; "é" }, '$buf from output_read contains UTF-8 bytes' );
}

# symbolic key
{
   use Term::VTerm qw( :keys );

   $vt->keyboard_key( KEY_ENTER );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 1, '->output_read after keyboard push symbolic ENTER' );
   is( $buf, chr 0x0d, '$buf from output_read' );
}

done_testing;
