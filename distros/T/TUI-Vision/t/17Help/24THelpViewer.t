use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpViewer';
  use_ok 'TUI::Help::HelpFile';
  use_ok 'TUI::Drivers::Const', qw(
    evCommand evKeyDown evMouseDown evNothing kbEnter kbEsc kbShiftTab
    kbTab meDoubleClick
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( cmClose sfModal sfSelected );
  use_ok 'TUI::Views::Group';
}

my $source = ".topic Start=10\n"
  . "See {next:Later} and {next:Other}.\n"
  . ".topic Later=20\n"
  . "Back {Start}.\n"
  . ".topic Other=30\n"
  . "Plain text.\n";

sub new_viewer {
  my ( $width, $height ) = @_;
  open my $stream, '<:raw', \$source or die $!;
  my $helpFile = THelpFile->new( stream => $stream );
  my $viewer = THelpViewer->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => $width, by => $height ),
    hScrollBar => undef,
    vScrollBar => undef,
    hFile      => $helpFile,
    context    => 10,
  );
  return $viewer;
}

sub key_event {
  my ( $keyCode ) = @_;
  return TEvent->new( what => evKeyDown, keyDown => { keyCode => $keyCode } );
}

subtest 'construction loads the topic and sets the scroll limit' => sub {
  my $viewer = new_viewer( 20, 5 );
  isa_ok( $viewer, 'TUI::Help::HelpViewer' );
  isa_ok( $viewer, 'TUI::Views::Scroller' );
  is( $viewer->selected, 1, 'selected starts at the first cross-reference' );
  is( $viewer->topic->getNumCrossRefs, 2,
    'topic exposes its cross-references' );
  is( $viewer->limit->{x}, 78, 'horizontal limit is 78 columns' );
  is( $viewer->limit->{y}, $viewer->topic->numLines,
    'vertical limit is the topic line count' );
};

subtest 'getPalette returns a palette' => sub {
  isa_ok( new_viewer( 20, 5 )->getPalette, 'TUI::Views::Palette' );
};

subtest 'Tab and Shift-Tab cycle through cross-references' => sub {
  my $viewer = new_viewer( 20, 5 );
  $viewer->handleEvent( key_event( kbTab ) );
  is( $viewer->selected, 2, 'Tab selects the next cross-reference' );
  $viewer->handleEvent( key_event( kbTab ) );
  is( $viewer->selected, 1, 'Tab wraps to the first cross-reference' );
  $viewer->handleEvent( key_event( kbShiftTab ) );
  is( $viewer->selected, 2, 'Shift-Tab wraps to the last cross-reference' );
};

subtest 'Enter switches to the selected topic' => sub {
  my $viewer = new_viewer( 20, 5 );
  $viewer->handleEvent( key_event( kbEnter ) );
  is( $viewer->topic->getNumCrossRefs, 1,
    'Enter loads the topic behind the selected reference' );
  is( $viewer->selected, 1, 'switching resets the selection' );
  is( $viewer->delta->{y}, 0, 'switching scrolls back to the top' );
};

subtest 'Esc is consumed' => sub {
  my $viewer = new_viewer( 20, 5 );
  my $event  = key_event( kbEsc );
  $viewer->handleEvent( $event );
  is( $event->{what}, evNothing, 'the Esc key event is consumed' );
};

subtest 'cmClose ends only a modal owner' => sub {
  my $group = TGroup->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
  );
  my $viewer = new_viewer( 20, 5 );
  $group->insert( $viewer );

  my $event = TEvent->new(
    what    => evCommand,
    message => { command => cmClose },
  );
  $viewer->handleEvent( $event );
  is( $event->{what}, evCommand, 'a non-modal owner leaves cmClose alone' );

  $group->{state} |= sfModal;
  $viewer->handleEvent( $event );
  is( $event->{what}, evNothing, 'a modal owner consumes cmClose' );
};

subtest 'double-clicking a cross-reference switches topics' => sub {
  my $viewer = new_viewer( 20, 5 );
  $viewer->setState( sfSelected, 1 );
  my $event = TEvent->new(
    what  => evMouseDown,
    mouse => {
      where      => TPoint->new( x => 4, y => 0 ),
      eventFlags => meDoubleClick,
    },
  );
  $viewer->handleEvent( $event );
  is( $viewer->topic->getNumCrossRefs, 1,
    'double-click loads the referenced topic' );
};


subtest 'changeBounds rewraps the topic to the new width' => sub {
  my $viewer = new_viewer( 20, 5 );
  $viewer->changeBounds(
    TRect->new( ax => 0, ay => 0, bx => 40, by => 10 ) );
  is( $viewer->limit->{y}, $viewer->topic->numLines,
    'the limit follows the rewrapped topic' );
};

subtest 'draw renders the topic without dying' => sub {
  my $viewer = new_viewer( 20, 5 );
  ok( eval { $viewer->draw; 1 }, 'draw completes' ) or diag $@;
};

done_testing;
