use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::StdDlg::DirListBox';
  use_ok 'TUI::StdDlg::DirCollection';
  use_ok 'TUI::Views::Group';
}

my $list;
my $owner;

subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 10 );
  $list = TDirListBox->new(
    bounds     => $bounds,
    vScrollBar => undef,
  );
  isa_ok( $list, TDirListBox() );

  $owner = TGroup->new( bounds => $bounds );
  isa_ok( $owner, TGroup() );
  $list->owner( $owner );
};

subtest 'newDirectory() test' => sub {
  lives_ok { $list->newDirectory( 'Drives' ) } 'newDirectory("Drives") lives';
  my $coll = $list->list;
  isa_ok( $coll, TDirCollection );
  ok( $coll->getCount, 'collection is not empty after Drives' );

  lives_ok { $list->newDirectory( 'C:\\' ) } 'newDirectory("C:\\") lives';
  $coll = $list->list;
  isa_ok( $coll, TDirCollection );
  ok( $coll->getCount, 'collection is not empty after directory change' );
};

done_testing();
