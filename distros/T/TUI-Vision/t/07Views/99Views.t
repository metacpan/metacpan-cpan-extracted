use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views';
}

is( cmValid, 0, 'cmValid is 0' );
isa_ok( new_TCommandSet(), TCommandSet );
isa_ok( new_TPalette( '', 0 ), TPalette );
isa_ok( new_TView( TRect->new() ), TView );
isa_ok( new_TGroup( TRect->new() ), TGroup );
isa_ok( new_TFrame( TRect->new() ), TFrame );
isa_ok( new_TScrollBar( TRect->new() ), TScrollBar );
isa_ok( new_TWindowInit( sub { } ), TWindowInit );
isa_ok( new_TWindow( TRect->new(), '', 0 ), TWindow );
isa_ok( new_TListViewer( TRect->new(), 0, undef, undef ), TListViewer );
ok( exists &message, 'message() exists' );

done_testing();
