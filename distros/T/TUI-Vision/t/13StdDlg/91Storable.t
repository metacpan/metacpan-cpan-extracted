use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::StdDlg::FileList';
  use_ok 'TUI::StdDlg::Const', qw( fdNoLoadDir cdNoLoadDir );
  use_ok 'TUI::StdDlg::FileInputLine';
  use_ok 'TUI::StdDlg::FileDialog';
  use_ok 'TUI::StdDlg::DirListBox';
  use_ok 'TUI::StdDlg::ChDirDialog';
}

subtest 'TFileList Storable roundtrip' => sub {
  my $fileList = TFileList->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    vScrollBar => undef,
  );

  my $restored = thaw( freeze( $fileList ) );
  isa_ok( $restored, TFileList );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is( $restored->{numCols}, 2, 'build preserves file list column count' );
  is( $restored->{range}, 0, 'preserves empty list range' );
  is( $restored->{items}, undef, 'restores an empty file list' );
}; #/ 'TFileList Storable roundtrip' => sub

subtest 'TFileDialog Storable roundtrip' => sub {
  my $wildCard = '__tvision_storable_no_match_91__.zzz';
  my $fileDialog = TFileDialog->new(
    wildCard  => $wildCard,
    title     => 'Storable test',
    inputName => 'File name',
    options   => fdNoLoadDir,
    histId    => 0,
  );

  my $serialized = freeze( $fileDialog );
  my $restored;
  {
    no warnings 'redefine';
    local *TUI::StdDlg::FileList::readDirectory = sub { return; };
    $restored = thaw( $serialized );
  }
  isa_ok( $restored, TFileDialog );
  is( $restored->{wildCard}, $wildCard, 'preserves wildcard' );
  is( $restored->{title}, 'Storable test', 'preserves inherited dialog title' );
  isa_ok( $restored->{fileName}, TFileInputLine );
  is( $restored->{fileName}{data}, $wildCard, 'restores file name input' );
  isa_ok( $restored->{fileList}, TFileList );
  is( $restored->{fileList}->list, undef, 'restores an empty file list' );
}; #/ 'TFileDialog Storable roundtrip' => sub

subtest 'TDirListBox Storable roundtrip' => sub {
  my $dirListBox = TDirListBox->new(
    bounds     => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    vScrollBar => undef,
  );

  my $restored = thaw( freeze( $dirListBox ) );
  isa_ok( $restored, TDirListBox );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is( $restored->{numCols}, 1, 'build preserves one column' );
  is( $restored->{range}, 0, 'preserves empty directory list range' );
  is( $restored->{items}, undef, 'restores an empty directory list' );
}; #/ 'TDirListBox Storable roundtrip' => sub

subtest 'TChDirDialog Storable roundtrip' => sub {
  my $dialog = TChDirDialog->new(
    options => cdNoLoadDir,
    histId  => 23,
  );
  my $serialized = freeze( $dialog );
  my $restored;
  {
    no warnings 'redefine';
    local *TUI::StdDlg::DirListBox::newDirectory = sub { return; };
    $restored = thaw( $serialized );
  }

  isa_ok( $restored, TChDirDialog );
  isa_ok( $restored->{dirList}, TDirListBox );
  is( $restored->{dirList}{numCols}, 1, 'restores directory list columns' );
  isa_ok( $restored->{dirInput}, 'TUI::Dialogs::InputLine' );
  is( $restored->{dirInput}{maxLen}, 68, 'restores directory input' );
  isa_ok( $restored->{okButton}, 'TUI::Dialogs::Button' );
  is( $restored->{okButton}{command}, $dialog->{okButton}{command},
    'restores OK button' );
  isa_ok( $restored->{chDirButton}, 'TUI::Dialogs::Button' );
  is( $restored->{chDirButton}{command}, $dialog->{chDirButton}{command},
    'restores change-directory button' );
}; #/ 'TChDirDialog Storable roundtrip' => sub

done_testing();
