use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw(
    gfGrowHiX
    gfGrowHiY
  );
  use_ok 'TUI::Gadgets::FileViewer';
}

sub testFile {
  my ( @lines ) = @_;

  my ( $fh, $fileName ) = tempfile();
  print {$fh} "$_\n" for @lines;
  close $fh;

  return $fileName;
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 5 );

subtest 'constructor and file loading' => sub {
  my $fileName = testFile(
    'First line',
    'A somewhat longer line',
    'Last line',
  );

  my $viewer;
  lives_ok { $viewer = new_TFileViewer( $bounds, undef, undef, $fileName ) }
    'constructor lives';

  isa_ok( $viewer, TFileViewer );
  ok( $viewer->isValid, 'file viewer is valid' );
  is( $viewer->fileName, $fileName, 'file name stored' );
  ok( $viewer->{growMode} & gfGrowHiX, 'grows horizontally' );
  ok( $viewer->{growMode} & gfGrowHiY, 'grows vertically' );

  is( $viewer->fileLines->getCount(), 3, 'all lines loaded' );
  is( $viewer->fileLines->at( 0 ), 'First line', 
    'first line stored' );
  is( $viewer->fileLines->at( 1 ), 'A somewhat longer line',
    'second line stored' );
  is( $viewer->{limit}{x}, length( 'A somewhat longer line' ),
    'horizontal limit uses longest line' );
  is( $viewer->{limit}{y}, 3, 'vertical limit uses line count' );

  unlink $fileName;
};

subtest 'readFile replaces contents' => sub {
  my $firstFile  = testFile( 'Old content' );
  my $secondFile = testFile( 'One', 'Two' );

  my $viewer = new_TFileViewer( $bounds, undef, undef, $firstFile );
  lives_ok { $viewer->readFile( $secondFile ) } 'readFile lives';

  ok( $viewer->isValid, 'replacement file is valid' );
  is( $viewer->fileName, $secondFile, 'file name replaced' );
  is( $viewer->fileLines->getCount(), 2, 'line collection replaced' );
  is( $viewer->fileLines->at( 0 ), 'One', 'new content loaded' );
  is( $viewer->{limit}{x}, 3, 'horizontal limit recalculated' );
  is( $viewer->{limit}{y}, 2, 'vertical limit recalculated' );

  unlink $firstFile;
  unlink $secondFile;
};

subtest 'valid' => sub {
  my $fileName = testFile( 'Valid file' );
  my $viewer = new_TFileViewer( $bounds, undef, undef, $fileName );

  ok( $viewer->valid( 0 ), 'valid returns true for loaded file' );

  unlink $fileName;
};

done_testing();
