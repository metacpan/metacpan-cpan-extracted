use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Validate';
}

isa_ok( new_TValidator(), TValidator );
isa_ok( new_TPXPictureValidator( '##??', !!0 ), TPXPictureValidator );
isa_ok( new_TFilterValidator( undef ), TFilterValidator );
isa_ok( new_TRangeValidator( 0, 100 ), TRangeValidator );
isa_ok( new_TLookupValidator(), TLookupValidator );
isa_ok( new_TStringLookupValidator( new_TStringCollection( 0, 0) ), 
  TStringLookupValidator );

done_testing();
