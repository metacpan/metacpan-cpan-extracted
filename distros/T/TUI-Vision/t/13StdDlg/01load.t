use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::StdDlg::Const';
  use_ok 'TUI::StdDlg::FindFirstRec';
  use_ok 'TUI::StdDlg::Dos';               # incl. ffblk and find_t
  use_ok 'TUI::StdDlg::Dir';
  use_ok 'TUI::StdDlg::Util', qw( fexpand );
  use_ok 'TUI::StdDlg::SortedListBox';
  use_ok 'TUI::StdDlg::FileCollection';    # incl. TSearchRec
  use_ok 'TUI::StdDlg::FileInputLine';
  use_ok 'TUI::StdDlg::FileList';
  use_ok 'TUI::StdDlg::FileInfoPane';
  use_ok 'TUI::StdDlg::FileDialog';
  use_ok 'TUI::StdDlg::DirEntry';
  use_ok 'TUI::StdDlg::DirCollection';
  use_ok 'TUI::StdDlg::DirListBox';
  use_ok 'TUI::StdDlg::ChDirDialog';
}

isa_ok( FindFirstRec->allocate( [], 0, '' ), FindFirstRec() );
isa_ok( ffblk->new(), 'ffblk' );
isa_ok( find_t->new(), 'find_t' );
isa_ok( TSearchRec->new(), 'TSearchRec' );
isa_ok( TSortedListBox->new( bounds => TRect->new(), numCols => 0, 
  vScrollBar => undef ), TSortedListBox() );
isa_ok( TFileCollection->new( limit => 0, delta => 0 ), TFileCollection );
isa_ok( TFileInputLine->new( bounds => TRect->new(), maxLen => 10, ), 
  TFileInputLine );
isa_ok( TFileList->new( bounds => TRect->new(), vScrollBar => undef ), 
  TFileList() );
isa_ok( TFileInfoPane->new( bounds => TRect->new() ), TFileInfoPane() );
isa_ok( TFileDialog->new( wildCard => '*.t', title => '', inputName => '', 
  options => 0, histId => 0 ), TFileDialog() );
isa_ok( TDirEntry->new( displayText => '', directory => '' ), TDirEntry() );
isa_ok( TDirCollection->new( limit => 0, delta => 0 ), TDirCollection() );
isa_ok( TDirListBox->new( bounds => TRect->new(), vScrollBar => undef ), 
  TDirListBox() );
isa_ok( TChDirDialog->new( options => 0, histId => 0 ), TChDirDialog() );

done_testing();
