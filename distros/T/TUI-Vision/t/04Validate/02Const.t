use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Validate::Const', qw( 
    :voXXXX
    :vsXXXX
    :vtXXXX
  );
}

is( vsOk,      0,      'vsOk is 0' );
is( vsSyntax,  1,      'vsSyntax is 1' );
is( voFill,    0x0001, 'voFill is 0x0001' );
is( vtGetData, 2,      'vtGetData is 2' );

done_testing();
