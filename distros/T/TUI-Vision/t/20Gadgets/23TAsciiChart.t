use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw(
    evKeyboard
    kbDown
    kbEnd
    kbHome
    kbLeft
    kbRight
    kbUp
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Gadgets::AsciiChart';
  use_ok 'TUI::Gadgets::Report';
  use_ok 'TUI::Gadgets::Table';
  use_ok 'TUI::Views::Const', qw( wfGrow wfZoom );
}

sub key_event {
  my ( $code ) = @_;
  return TEvent->new(
    what    => evKeyboard,
    keyDown => { keyCode => $code },
  );
}

sub char_event {
  my ( $char ) = @_;
  return TEvent->new(
    what    => evKeyboard,
    keyDown => { charScan => CharScanType->new( charCode => $char ) },
  );
}

my $chart = new_TAsciiChart();
my $table = $chart->firstThat( sub { $_[0]->isa( TTable() ) } );
my $report = $chart->firstThat( sub { $_[0]->isa( TReport() ) } );

subtest 'constructor' => sub {
  isa_ok( $chart, TAsciiChart() );
  is( $chart->{title}, 'ASCII Chart', 'title' );
  is( $chart->{size}{x}, 34, 'width' );
  is( $chart->{size}{y}, 12, 'height' );
  ok( !( $chart->{flags} & ( wfGrow | wfZoom ) ), 'not growable or zoomable' );
  isa_ok( $table, TTable() );
  isa_ok( $report, TReport() );
  is( $report->{asciiChar}, 0, 'report starts with character 0' );
};

subtest 'table keyboard navigation' => sub {
  $table->setCursor( 0, 0 );
  $table->handleEvent( key_event( kbRight ) );
  is( $table->{cursor}{x}, 1, 'kbRight moves right' );
  $table->handleEvent( key_event( kbDown ) );
  is( $table->{cursor}{y}, 1, 'kbDown moves down' );
  $table->handleEvent( key_event( kbLeft ) );
  $table->handleEvent( key_event( kbUp ) );
  is_deeply( [ $table->{cursor}{x}, $table->{cursor}{y} ], [ 0, 0 ],
    'kbLeft and kbUp move back' );

  $table->handleEvent( key_event( kbLeft ) );
  is( $table->{cursor}{x}, 0, 'kbLeft stops at left edge' );
  $table->handleEvent( key_event( kbUp ) );
  is( $table->{cursor}{y}, 0, 'kbUp stops at top edge' );

  $table->handleEvent( key_event( kbEnd ) );
  is_deeply( [ $table->{cursor}{x}, $table->{cursor}{y} ], [ 31, 7 ],
    'kbEnd moves to the last cell' );
  $table->handleEvent( key_event( kbRight ) );
  $table->handleEvent( key_event( kbDown ) );
  is_deeply( [ $table->{cursor}{x}, $table->{cursor}{y} ], [ 31, 7 ],
    'kbRight and kbDown stop at the bottom right edge' );

  $table->handleEvent( key_event( kbHome ) );
  is_deeply( [ $table->{cursor}{x}, $table->{cursor}{y} ], [ 0, 0 ],
    'kbHome moves to the first cell' );
};

subtest 'character key selects the cell of its code' => sub {
  $table->handleEvent( char_event( 65 ) );
  is_deeply( [ $table->{cursor}{x}, $table->{cursor}{y} ], [ 1, 2 ],
    'code 65 maps to column 1, row 2' );
};

subtest 'focused character is reported through the chart' => sub {
  $table->handleEvent( char_event( 65 ) );
  is( $report->{asciiChar}, 65, 'report stores the focused code' );

  $table->handleEvent( key_event( kbHome ) );
  is( $report->{asciiChar}, 0, 'report follows the cursor to code 0' );
};

done_testing();
