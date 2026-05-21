use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Dialogs::Const', qw( 
    :cpXXXX
    :bfXXXX
    :cmXXXX
    :dpXXXX
  );
}

is( substr( cpDialog, 0, 1 ), "\x20", 'cpBackground begins with "\x20"' );
is( bfDefault,                0x01,   'bfDefault is 0x01' );
is( cmRecordHistory,          60,     'cmRecordHistory is 60' );
is( dpCyanDialog,             1,      'dpCyanDialog is 1' );

done_testing();
