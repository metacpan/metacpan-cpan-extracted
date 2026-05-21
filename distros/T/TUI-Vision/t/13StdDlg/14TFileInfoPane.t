use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Group';
  use_ok 'TUI::StdDlg::FileInfoPane';
  use_ok 'TUI::StdDlg::FileCollection';   # incl. TSearchRec
  require_ok 'TUI::toolkit';
}

BEGIN {
  package MyOwner;
  use TUI::Views::Group;
  use TUI::toolkit;
  extends 'TUI::Views::Group';
  has wildCard  => ( is => 'rw' );
  has directory => ( is => 'rw' );
  $INC{"MyOwner.pm"} = 1;
}

BEGIN {
  package MyFileInfoPane;
  use TUI::StdDlg::FileInfoPane;
  use TUI::toolkit;
  extends 'TUI::StdDlg::FileInfoPane';
  sub writeLine { }
  $INC{"MyFileInfoPane.pm"} = 1;
}

use_ok 'MyOwner';
use_ok 'MyFileInfoPane';

my $pane;
my $owner;

subtest 'Object creation' => sub {
  my $bounds = TRect->new( ax => 0, ay => 0, bx => 80, by => 3 );

  $pane = MyFileInfoPane->new( bounds => $bounds );
  isa_ok( $pane, TFileInfoPane() );

  $owner = MyOwner->new( bounds => $bounds );
  isa_ok( $owner, TGroup() );

  # minimal owner data required by draw()
  $owner->{wildCard}  = '*.pl';
  $owner->{directory} = 'C:\\';

  $pane->owner( $owner );
};

subtest 'draw() without file' => sub {
  lives_ok { $pane->draw() } 'draw() lives without file_block';
};

subtest 'draw() with file_block' => sub {
  my $rec = TSearchRec->new(
    name => 'TEST.TXT',
    size => 12345,

    # DOS date/time:
    # 2024-03-15 14:23
    time => (
        ( ( 44 & 0x7F ) << 25 )    # year since 1980
      | ( ( 3  & 0x0F ) << 21 )    # month
      | ( ( 15 & 0x1F ) << 16 )    # day
      | ( ( 14 & 0x1F ) << 11 )    # hour
      | ( ( 23 & 0x3F ) << 5  )    # minute
    ),
  );

  $pane->{file_block} = $rec;

  lives_ok { $pane->draw() } 'draw() lives with file_block';
}; #/ 'draw() with file_block' => sub

done_testing;
