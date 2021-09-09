#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;

use Term::VTerm qw( :attrs );
use Term::VTerm::Color;

my $vt = Term::VTerm->new( cols => 80, rows => 25 );
$vt->set_utf8( 1 );

my $state = $vt->obtain_state;

isa_ok( $state, "Term::VTerm::State", '$state' );

$state->reset;

# position
{
   my $pos = $state->get_cursorpos;

   isa_ok( $pos, "Term::VTerm::Pos", '$pos' );
   is( $pos->row, 0, '$pos->row' );
   is( $pos->col, 0, '$pos->col' );

   $vt->input_write( "\e[5;10H" );

   $pos = $state->get_cursorpos;
   is( $pos->row, 4, '$pos->row after CUP' );
   is( $pos->col, 9, '$pos->col after CUP' );
}

# palette
{
   my ( $fg, $bg ) = $state->get_default_colors;

   isa_ok( $fg, "Term::VTerm::Color", '$fg' );
   ok( $fg->red,   '$fg->red > 0' );
   ok( $fg->green, '$fg->green > 0' );
   ok( $fg->blue,  '$fg->blue > 0' );

   isa_ok( $bg, "Term::VTerm::Color", '$bg' );
   ok( !$bg->red,   '$bg->red == 0' );
   ok( !$bg->green, '$bg->green == 0' );
   ok( !$bg->blue,  '$bg->blue == 0' );

   my $red = $state->get_palette_color( 1 );
   isa_ok( $red, "Term::VTerm::Color", '$red' );
   ok(  $red->red,   '$red->red > 0' );
   ok( !$red->green, '$red->green == 0' );
   ok( !$red->blue,  '$red->blue == 0' );

   $state->set_default_colors( Term::VTerm::Color->new( red => 255, green => 255, blue => 255 ), $bg );
   ( $fg ) = $state->get_default_colors;

   is( $fg->rgb_hex, "ffffff", '$fg->rgb_hex after $state->set_default_colors' );
}

# pen attrs
{
   my $val = $state->get_penattr( ATTR_BOLD );
   ok( defined $val, 'ATTR_BOLD is defined' );
   ok( !$val, 'ATTR_BOLD is false' );

   $val = $state->get_penattr( ATTR_FONT );
   is( $val, 0, 'ATTR_FONT is 0' );

   $val = $state->get_penattr( ATTR_FOREGROUND );
   isa_ok( $val, "Term::VTerm::Color", '$val from ATTR_FOREGROUND' );
   ok( defined $val->red,   '$val->red defined' );
   ok( defined $val->green, '$val->green defined' );
   ok( defined $val->blue,  '$val->blue defined' );
}

# query output
{
   $vt->input_write( "\e[5n" );

   my $len = $vt->output_read( my $buf, 128 );
   is( $len, 4, '->output_read with DSR query result pending' );
   is( $buf, "\e[0n", '$buf after ->output_read' );
}

# putglyph
{
   my ( $info, $pos );
   $state->set_callbacks(
      on_putglyph => sub { ( $info, $pos ) = @_ },
   );

   $vt->input_write( "\e[2;4HA" );

   is_deeply( [ $info->chars ], [ ord "A" ], '$info->chars after putglyph' );
   is( $info->str, "A", '$info->str after putglyph' );
   is( $info->width, 1,        '$info->width after putglyph' );
   ok( !$info->protected_cell, '$info->protected_cell after putglyph' );
   ok( !$info->dwl,            '$info->dwl after putglyph' );
   ok( !$info->dhl,            '$info->dhl after putglyph' );
   is( $pos->row, 1, '$pos->row after putglyph' );
   is( $pos->col, 3, '$pos->col after putglyph' );
}

# movecursor
{
   my ( $pos, $oldpos, $visible );
   $state->set_callbacks(
      on_movecursor => sub { ( $pos, $oldpos, $visible ) = @_ },
   );

   $vt->input_write( "\e[3;6H" );

   is( $pos->row, 2, '$pos->row after movecursor' );
   is( $pos->col, 5, '$pos->col after movecursor' );
}

# scrollrect
{
   my ( $rect, $down, $right );
   $state->set_callbacks(
      on_scrollrect => sub { ( $rect, $down, $right ) = @_; return 1; },
   );

   $vt->input_write( "\e[5H\e[L" );

   is( $rect->start_row, 4, '$rect->start_row after scrollrect' );
   is( $rect->start_col, 0, '$rect->start_col after scrollrect' );
   is( $rect->end_row, 25, '$rect->end_row after scrollrect' );
   is( $rect->end_col, 80, '$rect->end_col after scrollrect' );
   is( $down,  -1, '$down after scrollrect' );
   is( $right,  0, '$right after scrollrect' );
}

# moverect
{
   my ( $dest, $src );
   $state->set_callbacks(
      on_scrollrect => sub { return 0; },
      on_moverect   => sub { ( $dest, $src ) = @_; },
   );

   $vt->input_write( "\e[10H\e[3@" );

   is( $dest->start_row, 9, '$dest->start_row' );
   is( $dest->start_col, 3, '$dest->start_col' );
   is( $dest->end_row,  10, '$dest->end_row' );
   is( $dest->end_col,  80, '$dest->end_col' );
   is( $src->start_row,  9, '$src->start_row' );
   is( $src->start_col,  0, '$src->start_col' );
}

# erase
{
   my ( $rect, $selective );
   $state->set_callbacks(
      on_erase => sub { ( $rect, $selective ) = @_ },
   );

   $vt->input_write( "\e[H\e[2J" );

   is( $rect->start_row, 0, '$rect->start_row after erase' );
   is( $rect->start_col, 0, '$rect->start_col after erase' );
   is( $rect->end_row,  25, '$rect->end_row after erase' );
   is( $rect->end_col,  80, '$rect->end_col after erase' );
}

# initpen
{
   my $inited;
   $state->set_callbacks(
      on_initpen => sub { $inited++ },
   );

   $state->reset;

   is( $inited, 1, '$inited after initpen' );
}

# setpenattr
{
   use Term::VTerm qw( :attrs );

   my ( $attr, $value );
   $state->set_callbacks(
      on_setpenattr => sub { ( $attr, $value ) = @_; },
   );

   $vt->input_write( "\e[1m" );

   is( $attr, ATTR_BOLD, '$attr after setpenattr' );
   ok( $value, '$value after setpenattr' );
}

# settermprop
{
   use Term::VTerm qw( :props );

   my ( $prop, $value );
   $state->set_callbacks(
      on_settermprop => sub { ( $prop, $value ) = @_; },
   );

   $vt->input_write( "\e]2;Title\e\\" );

   is( $prop,  PROP_TITLE, '$prop after settermprop' );
   is( $value, "Title",    '$value after settermprop' );

   undef $value;

   $vt->input_write( "\e]2;Another" );
   ok( !defined $value, '$value not yet set after split write' );

   $vt->input_write( " Title\e\\" );
   is( $value, "Another Title", '$value after second split write' );
}

# bell
{
   my $belled;
   $state->set_callbacks(
      on_bell => sub { $belled++ },
   );

   $vt->input_write( "\a" );

   is( $belled, 1, '$belled after bell' );
}

# TODO - resize

# setlineinfo
{
   my ( $row, $info );
   $state->set_callbacks(
      on_setlineinfo => sub { ( $row, $info ) = @_; },
   );

   $vt->input_write( "\e#6" );

   is( $row,            0, '$row after setlineinfo' );
   ok( $info->doublewidth, '$info->doublewidth after setlineinfo' );
}

done_testing;
