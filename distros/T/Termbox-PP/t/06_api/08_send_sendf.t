use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return );
}

# -------------------------------------
note 'Test send raw bytes to terminal';
# -------------------------------------

subtest 'tb_send / tb_sendf' => sub {
  plan tests => 4;

  no warnings 'redefine';
  my @calls;
  local *Termbox::bytebuf_nputs = sub {
    my ($outref, $buf, $len) = @_;
    push @calls, [ $buf, $len ];
    return TB_OK;
  };

  local $Termbox::global->{outbuf} = '';

  is(tb_send("abc", 3), TB_OK, 'tb_send OK');
  is_deeply($calls[-1], ["abc", 3], 'tb_send forwards args');

  is(tb_sendf("x=%d", 7), TB_OK, 'tb_sendf OK');
  is_deeply(
    $calls[-1],
    ["x=7", bytes::length("x=7")],
    'tb_sendf formats and forwards'
  );
};

done_testing;
