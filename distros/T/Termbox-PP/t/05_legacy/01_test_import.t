use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :func :event :colors );
}

ok exists(&tb_set_func),              ':api';
ok exists(&tb_cell_buffer),           ':api';
ok exists(&TB_FUNC_EXTRACT_PRE),      ':func';
ok exists(&TB_FUNC_EXTRACT_POST),     ':func';
if (Termbox::TB_OPT_ATTR_W == 16) {
  ok exists(&TB_256_BLACK),           ':colors';
} else {
  ok exists(&TB_TRUECOLOR_BOLD),      ':colors';
  ok exists(&TB_TRUECOLOR_UNDERLINE), ':colors';
  ok exists(&TB_TRUECOLOR_REVERSE),   ':colors';
  ok exists(&TB_TRUECOLOR_ITALIC),    ':colors';
  ok exists(&TB_TRUECOLOR_BLINK),     ':colors';
  ok exists(&TB_TRUECOLOR_BLACK),     ':colors';
}
ok exists(&Termbox::TB_OPT_TRUECOLOR), 'TB_OPT_TRUECOLOR';

done_testing;
