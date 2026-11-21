use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Editors::Const', qw( 
    maxLineLength
    :cpXXXX
    :cmXXXX
    :efXXXX
    :smXXXX
    :ufXXXX
  );
}

is( maxLineLength,            256,    'maxLineLength is 256' );
is( substr( cpEditor, 0, 1 ), "\x06", 'cpEditor begins with "\x06"' );
is( cmCharLeft,               500,    'cmCharLeft is 500' );
is( smExtend,                 0x01,   'smExtend is 0x01' );
is( ufLine,                   0x02,   'ufLine is 0x02' );
is( efPromptOnReplace,        0x0004, 'efPromptOnReplace is 0x0004' );

done_testing();
