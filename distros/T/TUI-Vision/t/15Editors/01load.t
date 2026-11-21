use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Editors::Const', qw( maxLineLength ); 
  use_ok 'TUI::Editors::Util', qw( countLines );
  use_ok 'TUI::Editors::Indicator';
  use_ok 'TUI::Editors::Editor::Edits';
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::FileEditor';
  use_ok 'TUI::Editors::Memo';
  use_ok 'TUI::Editors::EditWindow';
}

isa_ok( TIndicator->new( bounds => TRect->new() ), TIndicator() );
isa_ok( TEditor->new( bounds => TRect->new(), hScrollBar => undef,
  vScrollBar => undef, indicator => undef, bufSize => 0 ), TEditor() );
isa_ok( TFileEditor->new( bounds => TRect->new(), hScrollBar => undef,
  vScrollBar => undef, indicator => undef, fileName => undef ), TFileEditor() );
isa_ok( TMemo->new( bounds => TRect->new(), hScrollBar => undef,
  vScrollBar => undef, indicator => undef, bufSize => 0 ), TMemo() );
isa_ok( TEditWindow->new( bounds => TRect->new(), fileName => undef,
  number => 0 ), TEditWindow() );

done_testing();
