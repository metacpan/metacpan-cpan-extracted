use strict;
use warnings;

use Test::More;
use TUI::toolkit;

use File::Spec;
use File::Temp qw( tempdir );

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( evBroadcast evNothing );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( sfVisible );
  use_ok 'TUI::Editors::Const', qw( cmUpdateTitle );
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::FileEditor';
  use_ok 'TUI::Editors::EditWindow';
}

my $dir = tempdir( CLEANUP => 1 );

sub new_edit_window {
  my ( $fileName ) = @_;
  return TEditWindow->new(
    bounds   => TRect->new( ax => 0, ay => 0, bx => 40, by => 12 ),
    fileName => $fileName,
    number   => 1,
  );
}

subtest 'the window hosts a file editor for the given file' => sub {
  my $path = File::Spec->catfile( $dir, 'notes.txt' );
  my $w = new_edit_window( $path );
  isa_ok( $w->{editor}, TFileEditor() );
  is( $w->{editor}{fileName}, $path, 'editor keeps the file name' );
  is( $w->getTitle( 80 ), $path, 'title is the file name' );
};

subtest 'an empty file name gives an untitled window' => sub {
  my $w = new_edit_window( '' );
  is( $w->getTitle( 80 ), 'Untitled', 'title is Untitled' );
};

subtest 'the scrollbars and the indicator start hidden' => sub {
  my $w = new_edit_window( '' );
  ok( !( $w->{editor}{hScrollBar}{state} & sfVisible ),
    'horizontal scrollbar is hidden' );
  ok( !( $w->{editor}{vScrollBar}{state} & sfVisible ),
    'vertical scrollbar is hidden' );
  ok( !( $w->{editor}{indicator}{state} & sfVisible ), 'indicator is hidden' );
};

subtest 'the clipboard window is titled Clipboard and hides on close' => sub {
  my $w = new_edit_window( '' );
  local $TUI::Editors::Editor::clipboard = $w->{editor};
  is( $w->getTitle( 80 ), 'Clipboard', 'title is Clipboard' );

  $w->{state} |= sfVisible;
  $w->close();
  ok( !( $w->{state} & sfVisible ), 'clipboard window is hidden, not closed' );
};

subtest 'cmUpdateTitle broadcast is handled and cleared' => sub {
  my $w = new_edit_window( '' );
  my $event = TEvent->new(
    what    => evBroadcast,
    message => { command => cmUpdateTitle, infoPtr => undef },
  );
  $w->handleEvent( $event );
  is( $event->{what}, evNothing, 'event is cleared' );
};

subtest 'sizeLimits sets the minimum size to 24 x 6' => sub {
  my $w = new_edit_window( '' );
  my ( $min, $max ) = ( TPoint->new(), TPoint->new() );
  $w->sizeLimits( $min, $max );
  is( $min->{x}, 24, 'minimum width is 24' );
  is( $min->{y}, 6, 'minimum height is 6' );
};

done_testing();
