use strict;
use warnings;

use Test::More;
use TUI::toolkit;

use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( evKeyDown evNothing kbTab );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::Memo';
}

sub new_memo {
  return TMemo->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 40, by => 8 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
}

subtest 'getData() stores the length and the text in the record' => sub {
  my $memo = new_memo();
  $memo->insertText( "hello\nworld", 11, false );
  my $rec = TMemoData->new();
  $memo->getData( $rec );
  is( $rec->length, 11, 'length is the buffer length' );
  is( $rec->buffer, "hello\nworld", 'buffer is the text' );
};

subtest 'setData() replaces the text and truncates to the length' => sub {
  my $memo = new_memo();
  $memo->insertText( "old text", 8, false );
  my $rec = TMemoData->new( length => 5, buffer => "newXXX" );
  $memo->setData( $rec );
  is( $memo->bufLen(), 5, 'buffer length is taken from the record' );
  is( $memo->{buffer}, "newXX", 'only length characters are used' );
  is( $memo->{curPtr}, 0, 'cursor is reset as by setBufLen()' );
};

subtest 'getData() and setData() round-trip the text' => sub {
  my $src = new_memo();
  $src->insertText( "line one\nline two", 17, false );
  my $rec = TMemoData->new();
  $src->getData( $rec );

  my $dst = new_memo();
  $dst->setData( $rec );
  is( $dst->{buffer}, "line one\nline two", 'text is copied' );
  is( $dst->bufLen(), 17, 'buffer length is copied' );
};

subtest 'handleEvent() ignores the Tab key' => sub {
  my $memo = new_memo();
  my $event = TEvent->new(
    what    => evKeyDown,
    keyDown => { keyCode => kbTab },
  );
  $memo->handleEvent( $event );
  is( $event->{what}, evKeyDown, 'the Tab key event is not cleared' );
  is( $memo->bufLen(), 0, 'the Tab key does not change the text' );
};

subtest 'Storable round-trip keeps the text' => sub {
  my $memo = new_memo();
  $memo->insertText( "kept", 4, false );
  my $restored = thaw( freeze( $memo ) );
  isa_ok( $restored, 'TUI::Editors::Memo' );
  is( $restored->{buffer}, 'kept', 'text is streamed' );
};

done_testing();
