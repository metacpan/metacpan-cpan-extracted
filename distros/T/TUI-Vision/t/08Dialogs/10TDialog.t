use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    evBroadcast
    evCommand
    evKeyDown
    kbEsc
    kbEnter
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::Const', qw(
    cmOK
    cmCancel
  );
  use_ok 'TUI::Dialogs::Dialog';
  require_ok 'TUI::toolkit';
}

# Mock putEvent and clearEvent
BEGIN {
  package MyDialog;
  use TUI::toolkit;
  extends 'TUI::Dialogs::Dialog';
  sub putEvent   { ::pass( 'putEvent called' ) }
  sub clearEvent { ::pass( 'clearEvent called' ) }
  $INC{"MyDialog.pm"} = 1;
}

use_ok 'MyDialog';

my (
  $bounds,
  $dialog,
);

# Test case for the constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
  $dialog = MyDialog->new( bounds => $bounds, title => 'TestDialog' );
  isa_ok( $dialog, TDialog, 'Created object is correct class' );
  ok( $dialog->{flags},   'Flags initialized' );
  ok( $dialog->{palette}, 'Palette initialized' );
};

# Test case Palette handling
subtest 'getPalette' => sub {
  my $palette = $dialog->getPalette();
  ok( $palette, 'Palette returned' );
  isa_ok( $palette, TPalette, 'Palette is a TPalette object' );
};

# Test case command validation
subtest 'valid' => sub {
  ok( $dialog->valid( cmCancel ), 'cmCancel should return true' );
  ok( $dialog->valid( cmOK ), 'cmOK should return true' );
};

# Test case Event handling
subtest 'handleEvent' => sub {
  # Test kbEsc => evCommand
  my $event = TEvent->new( what => evKeyDown, keyDown => { keyCode => kbEsc } );
  isa_ok( $event, TEvent, 'Event is a TEvent object' );
  lives_ok { $dialog->handleEvent( $event ) }
    'handleEvent executed without error';
  ok( $event->{what} == evCommand, '$event is an evCommand event');

  # Test kbEnter => evBroadcast
  $event->{what} = evKeyDown;
  $event->{keyDown}{keyCode} = kbEnter;
  lives_ok { $dialog->handleEvent( $event ) }
    'handleEvent executed for kbEnter';
  ok( $event->{what} == evBroadcast, '$event is an evBroadcast event');
}; #/ 'Event handling' => sub

done_testing();
