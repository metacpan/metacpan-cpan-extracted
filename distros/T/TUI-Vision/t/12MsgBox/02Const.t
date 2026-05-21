use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::MsgBox::Const', qw( :mfXXXX );
}

is( mfWarning,      0x0000, 'mfWarning is 0x0000' );
is( mfError,        0x0001, 'mfError is 0x0001' );
is( mfInformation,  0x0002, 'mfInformation is 0x0002' );
is( mfConfirmation, 0x0003, 'mfConfirmation is 0x0003' );

done_testing();
