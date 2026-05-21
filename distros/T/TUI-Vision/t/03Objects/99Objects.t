use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects';
}

is( ccNotFound, -1, 'ccNotFound is -1' );
isa_ok( new_TObject(), TObject );
isa_ok( new_TPoint( 0, 0 ), TPoint );
isa_ok( new_TRect( 0, 0, 0, 0 ), TRect );
isa_ok( new_TNSCollection(), TNSCollection );
isa_ok( new_TNSSortedCollection(), TNSSortedCollection );
isa_ok( new_TCollection(), TCollection );
isa_ok( new_TSortedCollection(), TSortedCollection );
isa_ok( new_TStringCollection( 0, 0 ), TStringCollection );

done_testing();
