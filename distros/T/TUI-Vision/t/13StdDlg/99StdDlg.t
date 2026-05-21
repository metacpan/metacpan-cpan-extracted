use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::StdDlg';
}

isa_ok( new_TFileCollection( 0, 0 ), TFileCollection() );
isa_ok( new_TFileInputLine( TRect->new(), 0 ), TFileInputLine() );
isa_ok( new_TSortedListBox( TRect->new(), 0, undef ), TSortedListBox() );
isa_ok( new_TFileList( TRect->new(), undef ), TFileList() );
isa_ok( new_TFileInfoPane( TRect->new() ), TFileInfoPane() );
isa_ok( new_TFileDialog( '*.t', '', '', 0, 0 ), TFileDialog() );
isa_ok( new_TDirEntry( '', '' ), TDirEntry() );
isa_ok( new_TDirCollection( 0, 0 ), TDirCollection() );
isa_ok( new_TDirListBox( TRect->new(), undef ), TDirListBox() );
isa_ok( new_TChDirDialog( 0, 0 ), TChDirDialog() );

done_testing();
