use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Validate::Const', qw( vsOk );
  use_ok 'TUI::Validate::Validator';
  use_ok 'TUI::Validate::PXPictureValidator';
  use_ok 'TUI::Validate::FilterValidator';
  use_ok 'TUI::Validate::RangeValidator';
  use_ok 'TUI::Validate::LookupValidator';
  use_ok 'TUI::Validate::StringLookupValidator';
}

isa_ok( TValidator->new(), TValidator );
isa_ok( TPXPictureValidator->new( pic => '##??', autoFill => !!0 ), 
  TPXPictureValidator );
isa_ok( TFilterValidator->new( validChars => 'abc' ), TFilterValidator );
isa_ok( TRangeValidator->new( min => 0, max => 100 ), TRangeValidator );
isa_ok( TLookupValidator->new(), TLookupValidator );
isa_ok( TStringLookupValidator->new( 
  strings => TStringCollection->new( limit => 0, delta => 0) ), 
    TStringLookupValidator );

done_testing();
