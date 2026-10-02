use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Const', qw(
    kbCtrlA
    kbLeftCtrl
    kbRightCtrl
    evMouseDown
    mbLeftButton
    mbRightButton
    meMouseMoved
    meDoubleClick
  );
  use_ok 'TUI::Gadgets::PrintConstants', qw(
    printKeyCode
    printControlKeyState
    printEventCode
    printMouseButtonState
    printMouseWheelState
    printMouseEventFlags
  );
}

my $printFlags = sub { goto &TUI::Gadgets::PrintConstants::_printFlags };
my $printCode = sub { goto &TUI::Gadgets::PrintConstants::_printCode };

subtest 'Test &$printCode (match)' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  $printCode->( $os, kbCtrlA(), { kbCtrlA() => 'kbCtrlA' } );
  close $os;
  is( $output, "kbCtrlA", '&$printCode prints correct name for kbCtrlA' );
};

subtest 'Test &$printCode (no match)' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  $printCode->( $os, 0xFFFF, { kbCtrlA() => 'kbCtrlA' } );
  close $os;
  like( $output, qr/^0xFFFF/i, '&$printCode prints hex for unknown code' );
};

subtest 'Test &$printFlags' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  my %flags =
    ( kbLeftCtrl() => 'kbLeftCtrl', kbRightCtrl() => 'kbRightCtrl' );
  $printFlags->( $os, kbLeftCtrl() | kbRightCtrl(), \%flags );
  close $os;
  like( $output, qr/kb.*(Left|Ctrl)/, '&$printFlags print flags' );
};

subtest 'Test printKeyCode' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printKeyCode( $os, kbCtrlA() );
  close $os;
  like( $output, qr/kbCtrlA/, 'printKeyCode prints kbCtrlA' );
};

subtest 'Test printControlKeyState' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printControlKeyState( $os, kbLeftCtrl() | kbRightCtrl() );
  close $os;
  like( $output, qr/kb.*(Left|Ctrl)/, 'printControlKeyState print flags' );
};

subtest 'Test printEventCode' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printEventCode( $os, evMouseDown() );
  close $os;
  like( $output, qr/evMouseDown/, 'printEventCode prints evMouseDown' );
};

subtest 'Test printMouseButtonState' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printMouseButtonState( $os, mbLeftButton() | mbRightButton() );
  close $os;
  like( $output, qr/mb(Left|Right).*mb(Left|Right)/,
    'printMouseButtonState prints both buttons' );
};

subtest 'Test printMouseWheelState' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printMouseWheelState( $os, 0 );
  close $os;
  like( $output, qr/0x/,
    'printMouseWheelState prints hex if no constants defined' );
};

subtest 'Test printMouseEventFlags' => sub {
  my $output = '';
  open my $os, ">:scalar", \$output;
  printMouseEventFlags( $os, meMouseMoved() | meDoubleClick() );
  close $os;
  like( $output, qr/me.*me/,
    'printMouseEventFlags prints both flags' );
};

done_testing();
