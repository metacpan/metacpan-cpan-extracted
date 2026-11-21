use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Editors';
}

isa_ok( new_TIndicator( TRect->new() ), TIndicator() );
isa_ok( new_TEditor( TRect->new(), undef, undef, undef, 0 ), TEditor() );
isa_ok( new_TFileEditor( TRect->new(), undef, undef, undef, undef ), 
  TFileEditor() );
isa_ok( new_TMemo( TRect->new(), undef, undef, undef, 0 ), TMemo() );
isa_ok( new_TEditWindow( TRect->new(), undef, 0 ), TEditWindow() );

done_testing();
