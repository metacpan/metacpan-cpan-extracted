use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::Const', qw( bfDefault ); 
  use_ok 'TUI::Dialogs::Util', qw( hotKey );
  use_ok 'TUI::Dialogs::HistoryViewer::HistList';
  use_ok 'TUI::Dialogs::Dialog';
  use_ok 'TUI::Dialogs::Button';
  use_ok 'TUI::Dialogs::StaticText';
  use_ok 'TUI::Dialogs::ParamText';
  use_ok 'TUI::Dialogs::Label';
  use_ok 'TUI::Dialogs::InputLine';
  use_ok 'TUI::Dialogs::StrItem';
  use_ok 'TUI::Dialogs::Cluster';
  use_ok 'TUI::Dialogs::RadioButtons';
  use_ok 'TUI::Dialogs::CheckBoxes';
  use_ok 'TUI::Dialogs::MultiCheckBoxes';
  use_ok 'TUI::Dialogs::ListBox';
  use_ok 'TUI::Dialogs::HistInit';
  use_ok 'TUI::Dialogs::HistoryViewer';
  use_ok 'TUI::Dialogs::HistoryWindow';
  use_ok 'TUI::Dialogs::History';
}

isa_ok( TDialog->new( bounds => TRect->new(), title => 'title' ), TDialog );
isa_ok( TButton->new( bounds => TRect->new(), title => 'title', command => 0,
  flags => bfDefault ), TButton );
isa_ok( TStaticText->new( bounds => TRect->new(), text => 'text' ),
  TStaticText );
isa_ok( TParamText->new( bounds => TRect->new() ), TParamText );
isa_ok( TLabel->new( bounds => TRect->new(), text => 'text', link => undef ),
  TLabel );
isa_ok( TInputLine->new( bounds => TRect->new(), maxLen => 10, ), TInputLine );
isa_ok( TSItem->new( value => 'value',  next => undef ), TSItem );
isa_ok( TCluster->new( bounds => TRect->new(), strings => undef ), TCluster );
isa_ok( TRadioButtons->new( bounds => TRect->new(), strings => undef ), 
  TRadioButtons );
isa_ok( TCheckBoxes->new( bounds => TRect->new(), strings => undef ), 
  TCheckBoxes );
isa_ok( TMultiCheckBoxes->new( bounds => TRect->new(), strings => undef, 
  selRange => 3, flags => 0x0203, states => '-+*' ), TMultiCheckBoxes );
isa_ok( TListBox->new( bounds => TRect->new(), numCols => 0, 
  vScrollBar => undef ), TListBox );
isa_ok( THistInit->new( cListViewer => sub { } ), THistInit() );
isa_ok( THistoryWindow->new( bounds => TRect->new(), historyId => 0 
  ), THistoryWindow() );
isa_ok( THistory->new( bounds => TRect->new(), link => bless( {} ), 
  historyId => 0 ), THistory() );

done_testing();
