use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs';
}

ok( eval { clearHistory(); !$@ }, 'HisList successfully imported' );
is( hotKey('~K~ey'), 'K', 'Util successfully imported' );
isa_ok( new_TDialog( TRect->new(), '' ), TDialog );
isa_ok( new_TButton( TRect->new(), 'Title', 0, 0 ), TButton );
isa_ok( new_TStaticText( TRect->new(), 'Text' ), TStaticText );
isa_ok( new_TParamText( TRect->new() ), TParamText );
isa_ok( new_TLabel( TRect->new(), 'text', undef ), TLabel );
isa_ok( new_TInputLine( TRect->new(), 10 ), TInputLine );
isa_ok( new_TSItem( 'text', undef ), TSItem );
isa_ok( new_TCluster( TRect->new(), undef ), TCluster );
isa_ok( new_TRadioButtons( TRect->new(), undef ), TRadioButtons );
isa_ok( new_TCheckBoxes( TRect->new(), undef ), TCheckBoxes );
isa_ok( new_TMultiCheckBoxes( TRect->new(), undef, 3, 0x0203, '-+*' ), 
  TMultiCheckBoxes );
isa_ok( new_TListBox( TRect->new(), 0, undef ), TListBox );
isa_ok( new_THistInit( sub { } ), THistInit() );
isa_ok( new_THistoryWindow( TRect->new(), 0 ), THistoryWindow() );
isa_ok( new_THistory( TRect->new(), bless( {} ), 0 ), THistory() );

done_testing();
