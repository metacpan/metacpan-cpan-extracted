#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;
use Test::Refcount;

use Term::VTerm;

use Encode qw( encode_utf8 );

my $vt = Term::VTerm->new( cols => 80, rows => 25 );
$vt->set_utf8( 1 );

# Refcounting probe
my $var;
is_refcount( \$var, 2, '\$var has refcount 2 initially' );

my $text;

$vt->parser_set_callbacks(
   on_text => sub { $text = $_[0]; undef $var },
);

is_refcount( \$var, 3, '\$var has refcount 3 when captured by callback closure' );

# text
{
   my $len = $vt->input_write( "abcde" );
   is( $len, 5, '->input_write consumed 5 bytes of text' );

   is( $text, "abcde", '$text after ->input_write' );

   $len = $vt->input_write( encode_utf8 "fĝh" );
   is( $len, 4, '->input_write consumed 4 bytes of UTF-8 text' );

   is( $text, "fĝh", '$text after ->input_write UTF-8' );
}

# control
{
   my $ctrl;
   $vt->parser_set_callbacks(
      on_control => sub { $ctrl = $_[0] },
   );

   my $len = $vt->input_write( "\t" );
   is( $len, 1, '->input_write consumed 1 byte of control' );

   is( $ctrl, ord "\t", '$ctrl after ->input_write' );
}

# escape
{
   my $esc;
   $vt->parser_set_callbacks(
      on_escape => sub { $esc = $_[0] },
   );
   $text = "";

   my $len = $vt->input_write( "\e(Dmore" );
   is( $len, 7, '->input_write consumed 7 bytes of ESC + text' );

   is( $esc, "(D", '$esc after ->input_write' );
   is( $text, "more", '$text after ->input_write' );
}

# csi
{
   my ( $csi_l, $csi_c, @csi_args );
   $vt->parser_set_callbacks(
      on_csi => sub { ( $csi_l, $csi_c, @csi_args ) = @_ },
   );

   my $len = $vt->input_write( "\e[>1:2;3:4;5A" );
   is( $len, 13, '->input_write consumed 13 bytes of CSI' );

   is( $csi_l, '>', '$csi_l after ->input_write full CSI' );
   is( $csi_c, 'A', '$csi_c after ->input_write full CSI' );

   is_deeply( \@csi_args, [ [ 1, 2 ], [ 3, 4 ], [ 5 ] ],
      '@csi_args after ->input_write full CSI' );

   $vt->input_write( "\e[6;B" );

   is( $csi_l, undef, '$csi_l undef after ->input_write small CSI' );
   is_deeply( \@csi_args, [ [ 6 ], [ undef ] ],
      '@csi_args after ->input_write small CSI' );
}

# osc
{
   my ( $osc_cmd, $osc_str );
   $vt->parser_set_callbacks(
      on_osc => sub { ( $osc_cmd, $osc_str ) = @_ },
   );

   my $len = $vt->input_write( "\e]15;ABCDE\e\\" );
   is( $len, 12, '->input_write consumed 12 bytes of OSC' );

   is( $osc_cmd, 15,      '$osc_cmd after ->input_write' );
   is( $osc_str, "ABCDE", '$osc_str after ->input_write' );

   undef $osc_cmd;

   $vt->input_write( "\e]20;abc" );
   ok( !defined $osc_cmd, '$osc_cmd not yet set after split write' );

   $vt->input_write( "de\e\\" );
   is( $osc_cmd, 20,      '$osc_cmd after ->input_write' );
   is( $osc_str, "abcde", '$osc_str after ->input_write' );
}

# dcs
{
   my ( $dcs_cmd, $dcs_str );
   $vt->parser_set_callbacks(
      on_dcs => sub { ( $dcs_cmd, $dcs_str ) = @_ },
   );

   my $len = $vt->input_write( "\ePFGHIJ\e\\" );
   is( $len, 9, '->input_write consumed 9 bytes of DCS' );

   is( $dcs_cmd, "F",    '$dcs_cmd after ->input_write' );
   is( $dcs_str, "GHIJ", '$dcs_str after ->input_write' );

   undef $dcs_cmd;

   $vt->input_write( "\ePfg" );
   ok( !defined $dcs_cmd, '$dcs_cmd not yet set after split write' );

   $vt->input_write( "hij\e\\" );
   is( $dcs_cmd, "f",    '$dcs_cmd after ->input_write' );
   is( $dcs_str, "ghij", '$dcs_str after ->input_write' );
}

# resize
{
   my ( $rows, $cols );
   $vt->parser_set_callbacks(
      on_resize  => sub { ( $rows, $cols ) = @_ },
   );

   $vt->set_size( 30, 100 );

   is( $rows,  30, '$rows after ->set_size' );
   is( $cols, 100, '$cols after ->set_size' );
}

undef $vt;

is_refcount( \$var, 2, '\$var has refcount 2 after undef $vt' );

done_testing;
