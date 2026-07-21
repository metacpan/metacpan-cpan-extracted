use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return :colors );
}

sub valid_preinit_status {
  my ($rv) = @_;
  return 1
    if $rv == TB_ERR_NOT_INIT()
    || $rv == TB_ERR_OUT_OF_BOUNDS()
    || $rv == TB_ERR();
  return 0;
}

# -------------------------------
note 'Back buffer clearing APIs';
# -------------------------------

subtest 'pre-init status checks' => sub {
  plan tests => 2;

  my $rv = tb_clear();
  ok(valid_preinit_status($rv), 'tb_clear returns expected pre-init status');

  $rv = tb_set_clear_attrs(TB_RED(), TB_BLUE());
  ok(
    valid_preinit_status($rv),
    'tb_set_clear_attrs returns expected pre-init status'
  );
};

subtest 'clear and set_clear_attrs after init' => sub {
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  plan tests => 2;

  my $rv = tb_set_clear_attrs(TB_RED(), TB_BLUE());
  is($rv, TB_OK(), 'tb_set_clear_attrs returns TB_OK after init');

  $rv = tb_clear();
  is($rv, TB_OK(), 'tb_clear returns TB_OK after init');
};

done_testing;
