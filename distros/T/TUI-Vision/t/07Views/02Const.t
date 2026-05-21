use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Views::Const', qw( :cmXXXX );
}

is( cmValid,    0,  'cmValid is 0' );
is( cmQuit,     1,  'cmQuit is 1' );
is( cmError,    2,  'cmError is 2' );
is( cmMenu,     3,  'cmMenu is 3' );
is( cmClose,    4,  'cmClose is 4' );
is( cmZoom,     5,  'cmZoom is 5' );
is( cmResize,   6,  'cmResize is 6' );
is( cmNext,     7,  'cmNext is 7' );
is( cmPrev,     8,  'cmPrev is 8' );
is( cmHelp,     9,  'cmHelp is 9' );
is( cmOK,       10, 'cmOK is 10' );
is( cmCancel,   11, 'cmCancel is 11' );
is( cmYes,      12, 'cmYes is 12' );
is( cmNo,       13, 'cmNo is 13' );
is( cmDefault,  14, 'cmDefault is 14' );
is( cmNew,      30, 'cmNew is 30' );
is( cmOpen,     31, 'cmOpen is 31' );
is( cmSave,     32, 'cmSave is 32' );
is( cmSaveAs,   33, 'cmSaveAs is 33' );
is( cmSaveAll,  34, 'cmSaveAll is 34' );
is( cmChDir,    35, 'cmChDir is 35' );
is( cmDosShell, 36, 'cmDosShell is 36' );
is( cmCloseAll, 37, 'cmCloseAll is 37' );

done_testing();
