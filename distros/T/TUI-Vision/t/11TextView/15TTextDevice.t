use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::TextView::TextDevice';
  use_ok 'TUI::Views::ScrollBar';
  require_ok 'TUI::toolkit';
}

# Create a subclass for tests that implements do_sputn
{
  package MyTextDevice;
  use TUI::toolkit;

  extends 'TUI::TextView::TextDevice';

  has io   => ( is => 'bare' );
  has data => ( is => 'ro', default => sub { '' } );

  sub BUILD    { open( $_[0]->{io}, '>:raw', \$_[0]->{data} ) }
  sub do_sputn { shift->{io}->print(shift); shift }
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );
my $hBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
my $vBar = TScrollBar->new(
  bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );

# Test object creation
my $device;
subtest 'Object creation' => sub {
  lives_ok { 
    $device = MyTextDevice->from( $bounds, $hBar, $vBar ) 
  } 'TTextDevice object created';
  isa_ok( $device, TTextDevice );
};

# Test overflow with a character
subtest 'overflow' => sub {
  can_ok( $device, 'overflow' );
  my $result = $device->overflow(ord('A'));
  is($result, 1, 'overflow returns 1');
  is($device->data, 'A', 'do_sputn was called with A');
};

# Test syswrite with a character
subtest 'syswrite' => sub {
  can_ok( $device, 'syswrite' );
  my $result = $device->syswrite('BB', 2);
  is($result, 2, 'syswrite returns 2');
  is(substr($device->data, 1), 'BB', 'do_sputn was called with BB');
};

# Test some tied text device methods
subtest 'tied text device' => sub {
  my $buf = '';
  tie *TXT, MyTextDevice=>(
    bounds      => new_TRect( 0, 0, 20, 10 ),
    vScrollBar => $hBar,
    hScrollBar => $vBar,
  );
  my $device = tied(*TXT);
  isa_ok( $device, TTextDevice );

  lives_ok { print(TXT "print\n")  or die } 'print TXT';
  lives_ok { printf(TXT 'printf')  or die } 'print TXT';
  lives_ok { read(TXT, $buf, 1)    // die } 'read TXT, ...';
  lives_ok { sysread(TXT, $buf, 1) // die } 'sysread TXT, ...';
  lives_ok { eof TXT               or die } 'eof TXT';
  lives_ok { my $line = <TXT>      // die } '$_ = <TXT>';
  lives_ok { my @lines = <TXT>     // die } '@_ = <TXT>';
  lives_ok { binmode( TXT )        // die } 'binmode TXT';

  lives_ok { syswrite(TXT, 'CCC')  // die } 'syswrite TXT, ...';
  is( $device->data, 'CCC', 'valid data w/o flush' );
  lives_ok { close TXT             or die } 'close TXT';
  like( $device->data, qr/^CCCprint\n.+/, 'valid data after close w/ flush' );

  dies_ok  { seek(TXT, 0, 0)       or die } 'seek TXT, ...';
  dies_ok  { getc TXT              or die } 'getc TXT';
  dies_ok  { tell TXT              or die } 'tell TXT';
};

done_testing();
