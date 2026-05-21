use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Const';
  use_ok 'TUI::Objects::Object';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::NSCollection';
  use_ok 'TUI::Objects::NSSortedCollection';
  use_ok 'TUI::Objects::Collection';
  use_ok 'TUI::Objects::SortedCollection';
  use_ok 'TUI::Objects::StringCollection';
}

isa_ok( TObject->new(), TObject );
isa_ok( TPoint->new(), TPoint );
isa_ok( TRect->new(), TRect );
isa_ok( TNSCollection->new(), TNSCollection );
isa_ok( TNSSortedCollection->new(), TNSSortedCollection );
isa_ok( TCollection->new(), TCollection );
isa_ok( TSortedCollection->new(), TSortedCollection );
isa_ok( TStringCollection->new( limit => 0, delta => 0 ), TStringCollection );

done_testing();
