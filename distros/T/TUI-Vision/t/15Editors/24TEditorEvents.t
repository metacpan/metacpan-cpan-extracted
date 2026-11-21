use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( evNothing evKeyDown evCommand :kbXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( :cmXXXX sfActive sfVisible );
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Editors::Const', qw( cmCharLeft cmTextEnd cmFind );
  use_ok 'TUI::Editors::Indicator';
  use_ok 'TUI::Editors::Editor';
}

sub new_editor {
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef, 
    vScrollBar => undef, 
    indicator  => undef, 
    bufSize    => 0,
  );
  $e->insertText( "abc\r\ndef", 8, !!0 );
  return $e;
}

sub key {
  my ( $code ) = @_;
  return TEvent->new( what => evKeyDown, keyDown => { keyCode => $code } );
}

sub command {
  my ( $cmd ) = @_;
  return TEvent->new( what => evCommand, message => { command => $cmd } );
}

subtest 'setState(sfActive) shows and hides the indicator' => sub {
  my $ind = TIndicator->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 8, by => 1 ) 
  );
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef, vScrollBar => undef, indicator => $ind, bufSize => 0
  );
  $e->setState( sfActive, !!1 );
  ok( $ind->{state} & sfVisible,
    'indicator is shown when the editor becomes active' );
  $e->setState( sfActive, !!0 );
  ok( !( $ind->{state} & sfVisible ),
    'indicator is hidden when the editor is deactivated' );
};

subtest 'setCmdState() enables commands only while editor is active' => sub {
  my $e = new_editor();
  $e->setSelect( 0, 3, !!0 );
  $e->setCmdState( cmCut, !!1 );
  ok( !TView->commandEnabled( cmCut ),
    'an inactive editor does not enable cmCut' );
  $e->setState( sfActive, !!1 );
  ok( TView->commandEnabled( cmCut ),
    'an active editor with a selection enables cmCut' );
  $e->setState( sfActive, !!0 );
  ok( !TView->commandEnabled( cmCut ), 
    'deactivating the editor disables cmCut' );
};

subtest 'convertEvent() maps quick keys after a prefix key' => sub {
  my $e = new_editor();
  my $ev = key( kbCtrlQ );
  $e->convertEvent( $ev );
  is( $ev->{what}, evNothing, 'the prefix key Ctrl-Q is consumed' );
  $ev = key( ord 'F' );
  $e->convertEvent( $ev );
  is( $ev->{what}, evCommand, 'Ctrl-Q F becomes a command event' );
  is( $ev->{message}{command}, cmFind, 'Ctrl-Q F maps to cmFind' );
};

subtest 'cursor keys move the cursor' => sub {
  my $e = new_editor();
  $e->handleEvent( key( kbLeft ) );
  is( $e->{curPtr}, 7, 'kbLeft moves one character left' );
  $e->handleEvent( key( kbRight ) );
  is( $e->{curPtr}, 8, 'kbRight moves one character right' );
  $e->handleEvent( key( kbHome ) );
  is( $e->{curPos}{x}, 0, 'kbHome moves to the line start' );
  $e->handleEvent( key( kbEnd ) );
  is( $e->{curPos}{x}, 3, 'kbEnd moves to the line end' );
};

subtest 'Enter inserts a line break at the cursor' => sub {
  my $e = new_editor();
  $e->setCurPtr( 3, 0 );
  $e->handleEvent( key( kbEnter ) );
  is( $e->{curPos}{y}, 1, 'cursor moves to the next line' );
  is( $e->{curPos}{x}, 0, 'cursor is at the start of the new line' );
  is( $e->{buffer}, "abc\n\r\ndef", 'line break is inserted at the cursor' );
};

subtest 'Shift+cursor key extends the selection' => sub {
  my $e = new_editor();
  $e->handleEvent( key( kbEnd ) );
  my $ev = key( kbLeft );    # Shift+Left as delivered by the Termbox backend
  $ev->{keyDown}{controlKeyState} = kbShift;
  $e->handleEvent( $ev );
  is( $e->{curPtr}, 7, 'Shift+Left moves the cursor one character left' );
  ok( $e->hasSelection(), 'Shift+Left creates a selection' );
  is( $e->{selStart}, 7, 'selection starts at the new cursor position' );
  is( $e->{selEnd}, 8, 'selection ends at the old cursor position' );
};

subtest 'printable keys insert text' => sub {
  my $e = new_editor();
  $e->handleEvent( key( ord 'x' ) );
  is( $e->{buffer}, "abc\r\ndefx", 'character is inserted at the cursor' );
  is( $e->{curPtr}, 9, 'cursor moves behind the inserted character' );
};

subtest 'kbDel deletes the character at the cursor' => sub {
  my $e = new_editor();
  $e->handleEvent( key( kbHome ) );
  $e->handleEvent( key( kbDel ) );
  is( $e->{buffer}, "abc\r\nef",
  'kbHome goes to line start, first character of line 2 removed' );
};

subtest 'commands are dispatched through the command table' => sub {
  my $e = new_editor();
  $e->handleEvent( command( cmTextEnd ) );
  is( $e->{curPtr}, 8, 'cmTextEnd moves to the end of the buffer' );
  $e->handleEvent( command( cmCharLeft ) );
  is( $e->{curPtr}, 7, 'cmCharLeft moves one character left' );
};

subtest 'quick keys (Ctrl-Q followed by a letter) are mapped' => sub {
  my $e = new_editor();
  $e->handleEvent( key( kbCtrlQ ) );
  is( $e->{keyState}, 1, 'Ctrl-Q waits for a second key' );
  $e->handleEvent( key( ord 'C' ) );
  is( $e->{curPtr}, 8, 'Ctrl-Q C moves to the end of the text' );
  is( $e->{keyState}, 0, 'key state is reset after the second key' );
};

subtest 'cmCopy and cmCut transfer the selection to the clipboard' => sub {
  my $clip = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
  local $TUI::Editors::Editor::clipboard = $clip;
  my $e = new_editor();
  $e->setSelect( 0, 3, !!0 );
  $e->handleEvent( command( cmCopy ) );
  is( $clip->{buffer}, 'abc', 'cmCopy copies the selection' );
  is( $e->{buffer}, "abc\r\ndef", 'cmCopy keeps the text' );
  $e->setSelect( 0, 3, !!0 );
  $e->handleEvent( command( cmCut ) );
  is( $e->{buffer}, "\r\ndef", 'cmCut removes the selection' );
  is( $clip->{buffer}, 'abc', 'cmCut copies the selection' );
};

subtest 'cmPaste inserts the clipboard at the cursor' => sub {
  my $clip = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
  $clip->insertText( 'XY', 2, !!1 );
  local $TUI::Editors::Editor::clipboard = $clip;
  my $e = new_editor();
  $e->setCurPtr( 3, 0 );
  $e->handleEvent( command( cmPaste ) );
  is( $e->{buffer}, "abcXY\r\ndef", 
    'clipboard text is inserted at the cursor' );
};

subtest 'cmUndo reverts the last change' => sub {
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
  $e->canUndo( !!0 );
  $e->insertText( "abc\r\ndef", 8, !!0 );
  $e->canUndo( !!1 );
  $e->handleEvent( key( ord 'x' ) );
  is( $e->{buffer}, "abc\r\ndefx", 'a character is inserted' );
  $e->handleEvent( command( cmUndo ) );
  is( $e->{buffer}, "abc\r\ndef", 'cmUndo removes the inserted character' );
};

done_testing();
