use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Termbox::PP';
  use_ok 'Termbox';
  use_ok 'Termbox::PP::Terminfo::Builtin';
  use_ok 'Terminal::WCWidth';
  use_ok 'Terminal::WCWidth::Tables';
}

done_testing;
