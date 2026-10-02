use strict;
use warnings;

use File::Temp qw( tempfile );
use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Views::Window';
  use_ok 'TUI::Views::Const', qw( ofTileable );
  use_ok 'TUI::Gadgets::FileViewer';
  use_ok 'TUI::Gadgets::FileWindow';
}

sub testFile {
  my ( @lines ) = @_;
  my ( $fh, $fileName ) = tempfile();
  print {$fh} "$_\n" for @lines;
  close $fh;
  return $fileName;
}

is(
  TFileWindow(),
  'TUI::Gadgets::FileWindow',
  'TFileWindow() returns package name'
);

my $class = TFileWindow();

subtest 'constructor' => sub {
  my $fileName = testFile(
    'Line one',
    'Line two',
  );

  my $win;
  lives_ok { $win = new_TFileWindow( $fileName ) } 'new_TFileWindow lives';

  isa_ok( $win, $class );
  isa_ok( $win, TWindow );

  is( $win->{title}, $fileName, 'window title set' );
  ok( $win->{options} & ofTileable, 'window is tileable' );

  unlink $fileName;
};

subtest 'contains file viewer' => sub {
  my $fileName = testFile(
    'Line one',
    'Line two',
  );

  my $win = new_TFileWindow( $fileName );

  my $viewer = $win->current();
  ok( $viewer, 'viewer found' );
  isa_ok( $viewer, TFileViewer );

  is(
    $viewer->fileName,
    $fileName,
    'viewer initialized with file name'
  );

  unlink $fileName;
};

done_testing();
