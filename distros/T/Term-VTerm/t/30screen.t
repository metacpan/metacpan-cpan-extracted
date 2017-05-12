#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Term::VTerm;

my $vt = Term::VTerm->new( cols => 80, rows => 25 );
$vt->set_utf8( 1 );

# Cell formatting tests are easier with known colours
$vt->obtain_state->set_default_colors(
   Term::VTerm::Color->new( red => 255, green => 255, blue => 255 ),
   Term::VTerm::Color->new( red => 0, green => 0, blue => 0 ),
);

my $screen = $vt->obtain_screen;

isa_ok( $screen, "Term::VTerm::Screen", '$screen' );

$screen->reset;

my $homepos = Term::VTerm::Pos->new( row => 0, col => 0 );

# get_cell empty
{
   my $cell = $screen->get_cell( $homepos );

   is_deeply( [ $cell->chars ], [], '$cell->chars of empty cell' );
   is( $cell->str, "", '$cell->str of empty cell' );
   is( $cell->width, 1, '$cell->width of empty cell' );
}

# get_cell ASCII
{
   $vt->input_write( "H" );

   my $cell = $screen->get_cell( $homepos );

   is_deeply( [ $cell->chars ], [ ord "H" ], '$cell->chars of plain ASCII cell' );
   is( $cell->str, "H", '$cell->str of plain ASCII cell' );
   is( $cell->width, 1, '$cell->width of plain ASCII' );

   # formatting
   ok( !$cell->bold,      '$cell is not bold' );
   ok( !$cell->underline, '$cell has no underline' );
   ok( !$cell->italic,    '$cell is not italic' );
   ok( !$cell->blink,     '$cell is not blinking' );
   ok( !$cell->reverse,   '$cell is not reversed' );
   ok( !$cell->strike,    '$cell is not strikethrough' );
   ok( !$cell->font,      '$cell has no altfont' );

   is( $cell->fg->rgb_hex, "ffffff", '$cell->fg' );
   is( $cell->bg->rgb_hex, "000000", '$cell->bg' );
}

# get_cell Unicode + combining
{
   $vt->input_write( "e\x{301}" );

   my $cell = $screen->get_cell( Term::VTerm::Pos->new( row => 0, col => 1 ) );

   is_deeply( [ $cell->chars ], [ ord "e", 0x301 ], '$cell->chars of plain UTF-8 cell' );
   is( $cell->str, "e\x{301}", '$cell->str of plain UTF-8 cell' );
   is( $cell->width, 1, '$cell->width of plain UTF-8' );
}

# get_cell formatting
{
   $vt->input_write( "\e[1;3;32ml\e[m" );

   my $cell = $screen->get_cell( Term::VTerm::Pos->new( row => 0, col => 2 ) );

   ok( $cell->bold,   '$cell is bold' );
   ok( $cell->italic, '$cell is italic' );
   ok( $cell->fg->green > 0, '$cell->fg has green' );
}

# altscreen switching
{
   $screen->enable_altscreen( 1 );

   $vt->input_write( "\e[H1" );

   is( $screen->get_cell( $homepos )->str, "1", '1 printed on !ALTSCREEN' );

   $vt->input_write( "\e[?1049h\e[H2" );

   is( $screen->get_cell( $homepos )->str, "2", '2 printed on ALTSCREEN' );

   $vt->input_write( "\e[?1049l" );

   is( $screen->get_cell( $homepos )->str, "1", '1 visible on !ALTSCREEN' );
}

# get_text
{
   $vt->input_write( "\e[HHello, world!" );

   is( $screen->get_text( Term::VTerm::Rect->new(
            start_row => 0, end_row => 1,
            start_col => 0, end_col => 20,
         ) ), "Hello, world!", '$screen->get_text' );
}

# damage
{
   my @rects;
   $screen->set_callbacks(
      on_damage => sub { push @rects, $_[0]; },
   );

   $vt->input_write( "\e[HABC" );

   is( scalar @rects, 3, '@rects is 3 after on_damage' );
   is( $rects[0]->start_row, 0, '$rect->start_row after on_damage' );
   is( $rects[0]->start_col, 0, '$rect->start_col after on_damage' );
   is( $rects[0]->end_row,   1, '$rect->end_row after on_damage' );
   is( $rects[0]->end_col,   1, '$rect->end_col after on_damage' );

   undef @rects;

   use Term::VTerm qw( :damage );
   $screen->set_damage_merge( DAMAGE_SCREEN );

   $vt->input_write( "DEF" );
   $screen->flush_damage;

   is( scalar @rects, 1, '@rects is 1 after on_damage with SCREEN merge size' );
   is( $rects[0]->start_row, 0, '$rect->start_row after on_damage' );
   is( $rects[0]->start_col, 3, '$rect->start_col after on_damage' );
   is( $rects[0]->end_row,   1, '$rect->end_row after on_damage' );
   is( $rects[0]->end_col,   6, '$rect->end_col after on_damage' );
}

# moverect
{
   my ( $dest, $src );
   $screen->set_callbacks(
      on_moverect => sub { ( $dest, $src ) = @_; },
   );

   $vt->input_write( "\e[10H\e[3@" );

   is( $dest->start_row, 9, '$dest->start_row' );
   is( $dest->start_col, 3, '$dest->start_col' );
   is( $dest->end_row,  10, '$dest->end_row' );
   is( $dest->end_col,  80, '$dest->end_col' );
   is( $src->start_row,  9, '$src->start_row' );
   is( $src->start_col,  0, '$src->start_col' );
}

# movecursor
{
   my ( $pos, $oldpos, $visible );
   $screen->set_callbacks(
      on_movecursor => sub { ( $pos, $oldpos, $visible ) = @_ },
   );

   $vt->input_write( "\e[3;6H" );

   is( $pos->row, 2, '$pos->row after movecursor' );
   is( $pos->col, 5, '$pos->col after movecursor' );
}

# settermprop
{
   use Term::VTerm qw( :props );

   my ( $prop, $value );
   $screen->set_callbacks(
      on_settermprop => sub { ( $prop, $value ) = @_; },
   );

   $vt->input_write( "\e]2;Title\e\\" );

   is( $prop,  PROP_TITLE, '$prop after settermprop' );
   is( $value, "Title",    '$value after settermprop' );
}

# bell
{
   my $belled;
   $screen->set_callbacks(
      on_bell => sub { $belled++ },
   );

   $vt->input_write( "\a" );

   is( $belled, 1, '$belled after bell' );
}

# resize
{
   my ( $rows, $cols );
   $screen->set_callbacks(
      on_resize => sub { ( $rows, $cols ) = @_ },
   );

   $vt->set_size( 30, 100 );

   is( $rows,  30, '$rows after resize' );
   is( $cols, 100, '$cols after resize' );
}

done_testing;
