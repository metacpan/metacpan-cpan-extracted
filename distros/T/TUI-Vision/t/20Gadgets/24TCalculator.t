use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( 
    evBroadcast 
    evKeyboard
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Dialogs::Button';
  use_ok 'TUI::Gadgets::CalcDisplay';
  use_ok 'TUI::Gadgets::Calculator';
  use_ok 'TUI::Gadgets::Const', qw( cmCalcButton );
}

sub char_event {
  my ( $char ) = @_;
  return TEvent->new(
    what    => evKeyboard,
    keyDown => { charScan => CharScanType->new( charCode => $char ) },
  );
}

sub press {
  my ( $display, $keys ) = @_;
  $display->handleEvent( char_event( ord $_ ) ) for split //, $keys;
  return;
}

my $calc    = new_TCalculator();
my $display = $calc->firstThat( sub { $_[0]->isa( TCalcDisplay() ) } );

subtest 'constructor' => sub {
  isa_ok( $calc, TCalculator() );
  is( $calc->{title}, 'Calculator', 'title' );
  isa_ok( $display, TCalcDisplay() );
  is( $display->{number}, '0', 'display starts with zero' );
};

subtest 'addition and equals' => sub {
  press( $display, '1+2=' );
  is( $display->{number}, '3', '1+2= shows 3' );
  is( $display->{sign}, ' ', 'no sign for a positive result' );
};

subtest 'division by zero shows an error until C' => sub {
  press( $display, '5/0=' );
  is( $display->{number}, 'Error', '5/0= shows Error' );
  press( $display, '7' );
  is( $display->{number}, 'Error', 'digits are ignored in the error state' );
  press( $display, 'C' );
  is( $display->{number}, '0', 'C clears the error' );
};

subtest 'percent of a sum' => sub {
  press( $display, '200+10%=' );
  is( $display->{number}, '220', '200+10%= shows 220' );
  press( $display, 'C' );
};

subtest 'sign toggle' => sub {
  press( $display, '5_' );
  is( $display->{sign}, '-', 'sign key makes the value negative' );
  press( $display, '+3=' );
  is( $display->{number}, '2', '-5+3= shows magnitude 2' );
  is( $display->{sign}, '-', 'and keeps the negative sign' );
  press( $display, 'C' );
};

subtest 'large results use %g formatting' => sub {
  press( $display, '1000*1000=' );
  like( $display->{number}, qr/\A1e\+0*6\z/,
    'product is formatted (exponent digits are platform specific)' );
  press( $display, 'C' );
};

subtest 'button broadcast feeds the display' => sub {
  my $button = $calc->firstThat( sub {
    $_[0]->isa( TButton() ) && $_[0]{title} eq '7';
  } );
  isa_ok( $button, TButton() );

  $display->handleEvent( TEvent->new(
    what    => evBroadcast,
    message => { command => cmCalcButton, infoPtr => $button },
  ) );
  is( $display->{number}, '7', 'broadcast of the 7 button shows 7' );
};

done_testing();
