use strict;
use warnings;

use Test::More;
use IO::Scalar;

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
  my $os     = IO::Scalar->new( \$output );
  $printCode->( $os, kbCtrlA(), { kbCtrlA() => 'kbCtrlA' } );
  is( $output, "kbCtrlA", '&$printCode prints correct name for kbCtrlA' );
};

subtest 'Test &$printCode (no match)' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  $printCode->( $os, 0xFFFF, { kbCtrlA() => 'kbCtrlA' } );
  like( $output, qr/^0xFFFF/i, '&$printCode prints hex for unknown code' );
};

subtest 'Test &$printFlags' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  my %flags =
    ( kbLeftCtrl() => 'kbLeftCtrl', kbRightCtrl() => 'kbRightCtrl' );
  ok( kbLeftCtrl() != kbRightCtrl(), 'kbLeftCtrl != kbRightCtrl' );
  $printFlags->( $os, kbLeftCtrl() | kbRightCtrl(), \%flags );
  like( $output, qr/kb(|Left|Right).*kb(|Left|Right)/, 
    '&$printFlags prints both flags' );
};

subtest 'Test printKeyCode' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printKeyCode( $os, kbCtrlA() );
  like( $output, qr/kbCtrlA/, 'printKeyCode prints kbCtrlA' );
};

subtest 'Test printControlKeyState' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printControlKeyState( $os, kbLeftCtrl() | kbRightCtrl() );
  like( $output, qr/kb(|Left|Right).*kb(|Left|Right)/, 
    'printControlKeyState prints both flags' );
};

subtest 'Test printEventCode' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printEventCode( $os, evMouseDown() );
  like( $output, qr/evMouseDown/, 'printEventCode prints evMouseDown' );
};

subtest 'Test printMouseButtonState' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printMouseButtonState( $os, mbLeftButton() | mbRightButton() );
  like( $output, qr/mb(Left|Right).*mb(Left|Right)/,
    'printMouseButtonState prints both buttons' );
};

subtest 'Test printMouseWheelState' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printMouseWheelState( $os, 0 );
  like( $output, qr/0x/,
    'printMouseWheelState prints hex if no constants defined' );
};

subtest 'Test printMouseEventFlags' => sub {
  my $output = '';
  my $os     = IO::Scalar->new( \$output );
  printMouseEventFlags( $os, meMouseMoved() | meDoubleClick() );
  like( $output, qr/me.*me/,
    'printMouseEventFlags prints both flags' );
};

done_testing();
