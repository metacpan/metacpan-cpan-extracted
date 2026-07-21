use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api );
}

# ------------------------------------
note 'Get terminal (buffer) size API';
# ------------------------------------

subtest 'size functions pre-init status checks' => sub {
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  plan tests => 2;

  my $rv = tb_width();
  ok($rv, 'tb_width returns expected pre-init status');

  $rv = tb_height();
  ok($rv, 'tb_height returns expected pre-init status');
};

done_testing;
