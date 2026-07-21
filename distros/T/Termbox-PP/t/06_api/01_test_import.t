use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :all );
}

ok exists(&Termbox::TB_VERSION_STR), 'TB_VERSION_STR';
ok exists(&tb_version),              ':api';
ok exists(&TB_KEY_CTRL_TILDE),       ':keys';
ok exists(&TB_DEFAULT),              ':color';
ok exists(&TB_BOLD),                 ':color';
ok exists(&TB_EVENT_KEY),            ':event';
ok exists(&TB_MOD_ALT),              ':event';
ok exists(&TB_INPUT_CURRENT),        ':event';
ok exists(&TB_OUTPUT_CURRENT),       ':event';
ok exists(&TB_OK),                   ':return';
ok exists(&TB_FUNC_EXTRACT_PRE),     ':func';

done_testing;
