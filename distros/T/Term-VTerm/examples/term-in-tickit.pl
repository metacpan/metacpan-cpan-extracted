#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use Tickit::Async;
use Tickit::Widgets qw( Border );

my $loop = IO::Async::Loop->new;

my $t = Tickit::Async->new(
   root => Tickit::Widget::Border->new(
      h_border => 4,
      v_border => 2,
      bg => ( 1 + int rand 6 ),
      child => my $widget = VTermWidget->new( bg => 0 ),
   )
);
$loop->add( $t );

$widget->take_focus;

$t->run;

package VTermWidget;
use base qw( Tickit::Widget );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;
use constant CAN_FOCUS => 1;

use Tickit::Style;
BEGIN {
   style_definition base =>
      '<Tab>'   => "",
      '<S-Tab>' => "";
}

use Term::VTerm;
use IO::Pty 1.12;

use IO::Async::Stream;

use Convert::Color::XTerm;
use Convert::Color::RGB8;

use List::Util qw( min max );

sub lines { 1 }
sub cols { 1 }

my %colcache;
sub _coltoidx
{
   my ( $col ) = @_;
   return $col->index if $col->is_indexed;

   my $rgb = $col->rgb_hex;

   return $colcache{$rgb} //= Convert::Color::RGB8->new( $col->red, $col->green, $col->blue )
      ->as_xterm->index;
}

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );

   my $vterm = $self->{vterm} = Term::VTerm->new(
      rows => 1,
      cols => 1, # will be set by reshape
   );
   $vterm->set_utf8( 1 );

   my $screen = $self->{screen} = $vterm->obtain_screen;
   $screen->set_callbacks(
      on_damage => sub {
         my ( $vtrect ) = @_;
         my $window = $self->window or return 1;

         $window->expose( Tickit::Rect->new(
            top    => $vtrect->start_row,
            bottom => $vtrect->end_row,
            left   => $vtrect->start_col,
            right  => $vtrect->end_col,
         ) );

         return 1;
      },
      on_moverect => sub {
         my ( $dest, $src ) = @_;
         my $window = $self->window or return 1;

         $window->scrollrect(
            Tickit::Rect->new(
               top    => min( $dest->start_row, $src->start_row ),
               bottom => max( $dest->end_row,   $src->end_row ),
               left   => min( $dest->start_col, $src->start_col ),
               right  => max( $dest->end_col,   $src->end_col ),
            ),
            $src->start_row - $dest->start_row,
            $src->start_col - $dest->start_col,
         );

         return 1;
      },
      on_movecursor => sub {
         my ( $pos, undef, $visible ) = @_;
         my $window = $self->window or return;

         if( $visible ) {
            $window->cursor_at( $pos->row, $pos->col );
            $window->cursor_visible( 1 );
         }
         else {
            $window->cursor_visible( 0 );
         }
      },
      on_settermprop => sub { 1 },
      # TODO: on_bell
   );

   $screen->enable_altscreen( 1 );
   $screen->set_damage_merge( Term::VTerm::DAMAGE_SCREEN );
   $screen->reset( 1 );

   my $pty = $self->{pty} = IO::Pty->new;
   $loop->add( my $stream = $self->{stream} = IO::Async::Stream->new(
      handle => $pty,
      on_read => sub {
         my ( undef, $buffref ) = @_;

         my $writtenlen = $vterm->input_write( $$buffref );

         substr( $$buffref, 0, $writtenlen, "" );

         $self->flush;

         return 0;
      }
   ) );

   my $slave = $pty->slave;
   $loop->open_child(
      setup => [
         stdin  => $slave,
         stdout => $slave,
         stderr => $slave,
      ],
      code => sub {
         close $pty;
         POSIX::setsid();

         exec $ENV{SHELL};
      },
      on_finish => sub {
         die "Shell exited\n";
      },
   );

   close $slave;

   return $self;
}

sub flush
{
   my $self = shift;

   $self->{screen}->flush_damage;

   if( $self->{vterm}->output_read( my $buf, 8192 ) ) {
      $self->{stream}->write( $buf );
   }
}

sub reshape
{
   my $self = shift;
   my $win = $self->window or return;

   $self->{vterm}->set_size( $win->lines, $win->cols );
   $self->{pty}->set_winsize( $win->lines, $win->cols );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $screen = $self->{screen};

   foreach my $line ( $rect->linerange ) {
      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $cell = $screen->get_cell( Term::VTerm::Pos->new( row => $line, col => $col ) );
         my $str = $cell->str;

         unless( length $str ) {
            $rb->erase_at( $line, $col, 1, Tickit::Pen->new(
               bg => _coltoidx( $cell->bg ),
            ) );
            next;
         }

         $rb->text_at( $line, $col, $str, Tickit::Pen->new(
            b => $cell->bold,
            u => $cell->underline,
            i => $cell->italic,
            rv => $cell->reverse,
            strike => $cell->strike,
            fg => _coltoidx( $cell->fg ),
            bg => _coltoidx( $cell->bg ),
         ) );
      }
   }
}

my %symcache;
sub _keynametosym
{
   my ( $name ) = @_;
   return $symcache{$name} //= do {
      my $func = Term::VTerm->can( "KEY_\U$name" );
      $func ? $func->() : 0;
   };
}

sub on_key
{
   my $self = shift;
   my ( $ev ) = @_;

   my $vterm = $self->{vterm};

   my $type = $ev->type;
   my $str  = $ev->str;

   # TODO: Tickit makes this really inconvenient
   my $basestr = $str;
   1 while $basestr =~ s/^[SCM]-//;

   my $codepoint = length $basestr == 1 ? ord $basestr : 0;

   if( $codepoint ) {
      $vterm->keyboard_unichar( $codepoint, $ev->mod );
   }
   elsif( my $key = _keynametosym( $basestr ) ) {
      $vterm->keyboard_key( $key, $ev->mod );
   }
   else {
      print STDERR "TODO: Convert $str into vterm constant\n";
   }

   $self->flush;
}

# TODO: on_mouse
