use strict;
use warnings;

use File::Temp qw( tempfile );
use Storable qw( freeze thaw );
use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets::FileViewer';
  use_ok 'TUI::Gadgets::FileWindow';
  use_ok 'TUI::Gadgets::EventViewer';
  use_ok 'TUI::Gadgets::AsciiChart';
  use_ok 'TUI::Gadgets::CalcDisplay';
  use_ok 'TUI::Gadgets::Calculator';
  use_ok 'TUI::Gadgets::CalendarView';
  use_ok 'TUI::Gadgets::CalendarWindow';
  use_ok 'TUI::Gadgets::PuzzleView';
  use_ok 'TUI::Gadgets::PuzzleWindow';
  use_ok 'TUI::Gadgets::Report';
}

subtest 'TFileViewer Storable roundtrip' => sub {
  my ( $fileHandle, $fileName ) = tempfile();
  print {$fileHandle} "First line\nA longer second line\nLast line\n";
  close $fileHandle;

  my $viewer = TFileViewer->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 9 ),
    hScrollBar => undef,
    vScrollBar => undef,
    fileName   => $fileName,
  );
  $viewer->{delta}{x} = 2;
  $viewer->{delta}{y} = 1;

  my $restored = thaw( freeze( $viewer ) );
  isa_ok( $restored, TFileViewer );
  is_deeply( $restored->{origin}, { x => 3,  y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 5 }, 'preserves size' );
  is( $restored->{fileName}, $fileName, 'preserves file name' );
  ok( $restored->isValid(), 'restores valid file state' );
  is( $restored->{fileLines}->getCount(), 3, 'reloads all file lines' );
  is( $restored->{fileLines}->at( 0 ), 'First line', 'restores first line' );
  is( $restored->{fileLines}->at( 1 ), 'A longer second line',
    'restores second line' );
  is( $restored->{limit}{x}, length( 'A longer second line' ),
    'recalculates horizontal limit' );
  is( $restored->{limit}{y}, 3, 'recalculates vertical limit' );
  is_deeply( $restored->{delta}, { x => 2, y => 1 }, 'preserves scroll delta' );

  unlink $fileName;
}; #/ 'TFileViewer Storable roundtrip' => sub

subtest 'TFileWindow Storable roundtrip' => sub {
  my ( $fileHandle, $fileName ) = tempfile();
  print {$fileHandle} "Window line one\nWindow line two\n";
  close $fileHandle;

  my $window = TFileWindow->new( fileName => $fileName );
  my $restored = thaw( freeze( $window ) );
  isa_ok( $restored, TFileWindow );
  is( $restored->{title}, $fileName, 'preserves window title' );

  my $viewer;
  $restored->forEach( sub {
    $viewer = $_[0]
      if $_[0]->isa( TFileViewer );
  }, undef );
  isa_ok( $viewer, TFileViewer );
  is( $viewer->{fileName}, $fileName, 'restores viewer file name' );
  ok( $viewer->isValid(), 'restores valid viewer state' );
  is( $viewer->{fileLines}->getCount(), 2, 'restores file lines' );
  is( $viewer->{fileLines}->at( 0 ), 'Window line one', 'restores first line' );
  is( 
    $viewer->{fileLines}->at( 1 ), 
    'Window line two',
    'restores second line'
  );

  unlink $fileName;
}; #/ 'TFileWindow Storable roundtrip' => sub

subtest 'TEventViewer Storable roundtrip' => sub {
  my $viewer = TEventViewer->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 33, by => 14 ),
    bufSize => 256,
  );
  $viewer->{stopped}    = 1;
  $viewer->{eventCount} = 12;

  my $restored = thaw( freeze( $viewer ) );
  isa_ok( $restored, TEventViewer );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 30, y => 10 }, 'preserves size' );
  is( $restored->{bufSize}, 256, 'preserves terminal buffer size' );
  ok( !$restored->{stopped}, 'resets stopped state' );
  is( $restored->{eventCount}, 0, 'resets event count' );
  is( $restored->{title}, 'Event Viewer', 'restores active title' );
  isa_ok( $restored->{scrollBar}, 'TUI::Views::ScrollBar' );
  isa_ok( $restored->{interior}, 'TUI::TextView::Terminal' );
  is( 
    $restored->{interior}{bufSize}, 
    256, 
    'recreates terminal with saved size'
  );
}; #/ 'TEventViewer Storable roundtrip' => sub

subtest 'TReport Storable roundtrip' => sub {
  my $report = TReport->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 32, by => 1 ),
  );
  $report->{asciiChar} = 65;

  my $restored = thaw( freeze( $report ) );
  isa_ok( $restored, TReport );
  is( $restored->{asciiChar}, 65, 'preserves focused character' );
  is_deeply( $restored->{size}, { x => 32, y => 1 }, 'preserves size' );
}; #/ 'TReport Storable roundtrip' => sub

subtest 'TAsciiChart Storable roundtrip' => sub {
  my $chart = new_TAsciiChart();

  my $restored = thaw( freeze( $chart ) );
  isa_ok( $restored, TAsciiChart );
  is( $restored->{title}, 'ASCII Chart', 'preserves title' );

  my $children = sub {
    my ( $view ) = @_;
    my @types;
    $view->forEach( sub { push @types, ref $_[0] }, undef );
    return join ' ', sort @types;
  };
  is( $children->( $restored ), $children->( $chart ),
    'restores the same children without duplicates' );
}; #/ 'TAsciiChart Storable roundtrip' => sub

subtest 'TCalcDisplay Storable roundtrip' => sub {
  my $display = TCalcDisplay->new( 
    bounds => TRect->new( ax => 3, ay => 2, bx => 21, by => 3 )
  );
  $display->{number} = '42';
  $display->{sign}   = '-';

  my $restored = thaw( freeze( $display ) );
  isa_ok( $restored, TCalcDisplay );
  is( $restored->{number}, '42', 'preserves displayed number' );
  is( $restored->{sign}, '-', 'preserves sign' );
  is_deeply( $restored->{size}, { x => 18, y => 1 }, 'preserves size' );
}; #/ 'TCalcDisplay Storable roundtrip' => sub

subtest 'TCalculator Storable roundtrip' => sub {
  my $calc = TCalculator->new();

  my $restored = thaw( freeze( $calc ) );
  isa_ok( $restored, TCalculator );
  is( $restored->{title}, 'Calculator', 'preserves title' );

  my $children = sub {
    my ( $view ) = @_;
    my @types;
    $view->forEach( sub { push @types, ref $_[0] }, undef );
    return join ' ', sort @types;
  };
  is( $children->( $restored ), $children->( $calc ),
    'restores the same children without duplicates' );
}; #/ 'TCalculator Storable roundtrip' => sub

subtest 'TCalendarView Storable roundtrip' => sub {
  my $calendar = TCalendarView->new( 
    bounds => TRect->new( ax => 0, ay => 0, bx => 22, by => 9 ) 
  );
  $calendar->{month} = 3;
  $calendar->{year}  = 2031;

  my $restored = thaw( freeze( $calendar ) );
  isa_ok( $restored, TCalendarView );
  is( $restored->{month}, 3, 'preserves month' );
  is( $restored->{year}, 2031, 'preserves year' );
  is( $restored->{curYear}, $calendar->{curYear}, 'preserves current year' );
}; #/ 'TCalendarView Storable roundtrip' => sub

subtest 'TCalendarWindow Storable roundtrip' => sub {
  my $window = TCalendarWindow->new();

  my $restored = thaw( freeze( $window ) );
  isa_ok( $restored, TCalendarWindow );
  is( $restored->{title}, 'Calendar', 'preserves title' );
}; #/ 'TCalendarWindow Storable roundtrip' => sub

subtest 'TPuzzleView Storable roundtrip' => sub {
  my $puzzle = TPuzzleView->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 18, by => 4 )
  );
  $puzzle->{board}  = [ split //, 'ABCDEFGHIJKLMNO ' ];
  $puzzle->{moves}  = 7;
  $puzzle->{solved} = 1;

  my $restored = thaw( freeze( $puzzle ) );
  isa_ok( $restored, TPuzzleView );
  is( join( '', @{ $restored->{board} } ), 'ABCDEFGHIJKLMNO ',
    'preserves board' );
  is( $restored->{moves}, 7, 'preserves moves' );
  is( $restored->{solved}, 1, 'preserves solved state' );
}; #/ 'TPuzzleView Storable roundtrip' => sub

done_testing();