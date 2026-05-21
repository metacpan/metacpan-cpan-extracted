use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::StdDlg::FileCollection';
  use_ok 'TUI::StdDlg::FileList';
  use_ok 'TUI::Views::Group';
}

my $list;
my $owner;

subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );
  $list = TFileList->new( bounds => $bounds, vScrollBar => undef );
  isa_ok( $list, TFileList() );

  $owner = TGroup->new( bounds => $bounds);
  isa_ok( $owner, TGroup() );

  $list->owner( $owner );
};

subtest 'readDirectory()' => sub {
  lives_ok { $list->readDirectory( '*' ) } 'readDirectory lives';

  my $coll = $list->list;
  isa_ok( $coll, TFileCollection );
  ok( $coll->getCount, 'collection is not empty' );

  lives_ok { $list->readDirectory( '~\\temp\\', '*' ) }
    'readDirectory lives with two arguments results';
};

done_testing();
