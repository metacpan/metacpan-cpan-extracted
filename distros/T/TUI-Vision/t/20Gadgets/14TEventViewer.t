use strict;
use warnings;

use Test::More;

require bytes;
use Encode qw( decode );

BEGIN {
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::Const', qw(
    evKeyboard
    evMouse
    evCommand
  );
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::TextView::Terminal';
  use_ok 'TUI::Gadgets::EventViewer';
}

my $printEvent = sub { goto &TUI::Gadgets::EventViewer::_printEvent };

my $sample_event = TEvent->new(
  what    => evKeyboard,
  keyDown => {
    charScan => CharScanType->new(
      charCode => 164,    # CP437 character (ñ)
      scanCode => 0,
    ),
    keyCode         => 0xA4,
    controlKeyState => 0,
  },
);
ok( $sample_event, 'Sample keyboard event' );

my $mouse_event = TEvent->new(
  what  => evMouse,
  mouse => {
    where           => { x => 10, y => 20 },
    eventFlags      => 0x01,
    controlKeyState => 0x02,
    buttons         => 0x04,
  }
);
ok( $mouse_event, 'Sample mouse event' );

my $command_event = TEvent->new(
  what    => evCommand,
  message => {
    command => 999,
    infoPtr => 12345,
  }
);
ok( $command_event, 'Sample command event' );

my $bounds = TRect->new();

subtest 'Decode CP437 character to UTF-8 bytes' => sub {
  my $decoded = bytes::substr(
    decode( 'cp437', chr $sample_event->{keyDown}{charScan}{charCode} ), 0 );
  is_deeply(
    [ unpack( 'C*', $decoded ) ], 
    [ 0xC3, 0xB1 ], 
    'UTF-8 bytes match expected values'
  );
};

subtest 'Print hex representation of UTF-8 bytes' => sub {
  my $decoded = bytes::substr(
    decode( 'cp437', chr $sample_event->{keyDown}{charScan}{charCode} ), 0 );
  my @utf8_bytes = unpack( 'C*', $decoded );
  my $hex_string = join ', ', map { sprintf "0x%02X", $_ } @utf8_bytes;
  is( $hex_string, '0xC3, 0xB1', 'Hex string matches expected output' );
};

subtest 'Text length calculation' => sub {
  my $text_length = bytes::length(
    chr $sample_event->{keyDown}{charScan}{charCode} );
  is( $text_length, 1, 'Text length is 1 byte for original CP437 charCode' );
};

subtest '&$printEvent output for keyboard event' => sub {
  my $viewer = TUI::Gadgets::EventViewer->new(
    bounds   => $bounds,
    bufSize => 10
  );
  my $output = '';
  open( my $OUT, '>', \$output ) or die "Cannot open scalar ref: $!";
  $viewer->$printEvent( $OUT, $sample_event );
  close $OUT;

  note $output;
  like( $output, qr/TEvent \{/,  'Output starts with TEvent block' );
  like( $output, qr/keyCode/,    'Output contains keyCode field' );
  like( $output, qr/charCode/,   'Output contains charCode field' );
  like( $output, qr/0xC3, 0xB1/, 'Output contains UTF-8 hex bytes for "n~"' );
}; #/ '&$printEvent output for keyboard event' => sub

subtest '&$printEvent output for mouse event' => sub {
  my $viewer = TUI::Gadgets::EventViewer->new(
    bounds   => $bounds,
    bufSize => 10
  );
  my $output = '';
  open( my $OUT, '>', \$output ) or die "Cannot open scalar ref: $!";
  $viewer->$printEvent( $OUT, $mouse_event );
  close $OUT;

  note $output;
  like( $output, qr/TEvent \{/, 'Output starts with TEvent block' );
  like( $output, qr/mouse = MouseEventType/,
    'Output contains mouse event block' );
  like( $output, qr/x = 10/,     'Output contains correct X coordinate' );
  like( $output, qr/y = 20/,     'Output contains correct Y coordinate' );
  like( $output, qr/eventFlags/, 'Output contains eventFlags field' );
  like( $output, qr/buttons/,    'Output contains buttons field' );
}; #/ '&$printEvent output for mouse event' => sub

subtest '&$printEvent output for command event' => sub {
  my $viewer = TUI::Gadgets::EventViewer->new(
    bounds   => $bounds,
    bufSize => 10
  );
  my $output = '';
  open( my $OUT, '>', \$output ) or die "Cannot open scalar ref: $!";
  $viewer->$printEvent( $OUT, $command_event );
  close $OUT;

  note $output;
  like( $output, qr/TEvent \{/, 'Output starts with TEvent block' );
  like( $output, qr/message = MessageEvent/,
    'Output contains message event block' );
  like( $output, qr/command = 999/,   'Output contains correct command value' );
  like( $output, qr/infoPtr = 12345/, 'Output contains correct infoPtr value' );
}; #/ '&$printEvent output for command event' => sub

done_testing();
