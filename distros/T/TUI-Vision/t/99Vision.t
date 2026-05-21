use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Vision';
}

ok( defined &INT_MAX, 'Const: INT_MAX imported' );
ok( defined &TObject, 'Objects: TObject helper imported' );
ok( defined &TApplication, 'App: TApplication helper imported' );
ok( defined &TWindow, 'Views: TWindow helper imported' );
ok( defined &TDialog, 'Dialogs: TDialog helper imported' );
ok( defined &TMenuBar, 'Menus: TMenuBar helper imported' );
ok( defined &TScreen, 'Drivers: TScreen helper imported' );
ok( defined &TClockView, 'Gadgets: TClockView helper imported' );
ok( defined &TFileDialog, 'StdDlg: TFileDialog helper imported' );
ok( defined &messageBox, 'MsgBox: messageBox imported' );
ok( defined &TTerminal, 'TextView: TTerminal helper imported' );
ok( defined &lowMemory, 'Memory: lowMemory imported' );
ok( defined &true, 'toolkit: true imported' );
ok( defined &vsOk, 'Validate: vsOk constant imported' );

done_testing();
