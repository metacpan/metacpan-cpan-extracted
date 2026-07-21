use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
  # enable extended grapheme
  $ENV{TB_LIB_OPTS} = 0;
  $ENV{TB_OPT_EGC} = 1;
}

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return );
}

sub valid_preinit_status {
  my ($rv) = @_;
  return 1
    if $rv == TB_ERR_NOT_INIT()
    || $rv == TB_ERR_OUT_OF_BOUNDS()
    || $rv == TB_ERR();
  return 0;
}

# --------------------------------
note 'Print and printf functions';
# --------------------------------

subtest 'tb_print and tb_print_ex' => sub {
  plan tests => 6;

  my $rv = tb_print(0, 0, 0, 0, 'Hello');
  ok(valid_preinit_status($rv), 'tb_print returns a valid status');

  my $out_w = -1;
  $rv = tb_print_ex(0, 0, 0, 0, \$out_w, 'Hello');
  ok(valid_preinit_status($rv), 'tb_print_ex returns a valid status');

  if ($rv >= 0) {
    cmp_ok($out_w, '>=', 0, 'tb_print_ex sets non-negative out_w on success');
  } else {
    pass('tb_print_ex out_w check skipped due non-success status');
  }

  $rv = tb_print_ex(0, 0, 0, 0, undef, "A\nB");
  ok(valid_preinit_status($rv), 'tb_print_ex handles newline input');

  $rv = tb_print_ex(0, 0, 0, 0, undef, "");
  ok(valid_preinit_status($rv), 'tb_print_ex handles empty string');

  $rv = eval { tb_print_ex(-1, -1, 0, 0, undef, 'X') } // TB_ERR();
  ok(valid_preinit_status($rv), 'tb_print_ex handles invalid position');
};

subtest 'tb_print_ex combining char uses extend path' => sub {
  $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  my $rv = Termbox::init_cellbuf();
  plan skip_all => 'init_cellbuf failed in this environment'
    if $rv != TB_OK();

  plan tests => 4;

  my $out_w = -1;
  $rv = tb_print_ex(0, 0, 0, 0, \$out_w, "A\x{0301}");
  is($rv, TB_OK(), 'tb_print_ex accepts base plus combining char');
  is($out_w, 1, 'combining char does not increase out_w');

  my $cells;
  {
    local $SIG{__WARN__} = sub { };
    $cells = tb_cell_buffer();
  }
  is($cells->[0][0], "A\x{0301}", 'cell keeps combined grapheme');
  {
    local $SIG{__WARN__} = sub { };
    is(Termbox::tb_deinit(), TB_OK(), 'tb_deinit succeeds');
  }
};

subtest 'tb_printf and tb_printf_ex' => sub {
  plan tests => 4;

  my $rv = tb_printf(0, 0, 0, 0, '%s-%d', 'N', 1);
  ok(valid_preinit_status($rv), 'tb_printf returns a valid status');

  my $out_w = -1;
  $rv = tb_printf_ex(0, 0, 0, 0, \$out_w, '%s', 'Hello');
  ok(valid_preinit_status($rv), 'tb_printf_ex returns a valid status');

  if ($rv >= 0) {
    cmp_ok($out_w, '>=', 0, 'tb_printf_ex sets non-negative out_w on success');
  } else {
    pass('tb_printf_ex out_w check skipped due non-success status');
  }

  $rv = tb_printf_ex(0, 0, 0, 0, \$out_w, '');
  ok(valid_preinit_status($rv), 'tb_printf_ex handles empty format string');
};

done_testing();
