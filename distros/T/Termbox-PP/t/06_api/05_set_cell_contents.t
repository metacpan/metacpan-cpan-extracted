use 5.010;
use strict;
use warnings;

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

# -----------------------
note 'Cell content APIs';
# -----------------------

subtest 'pre-init status checks' => sub {
  plan tests => 4;

  my $rv = tb_set_cell(0, 0, 'A', 0, 0);
  ok(valid_preinit_status($rv), 'tb_set_cell returns expected pre-init status');

  $rv = tb_set_cell_ex(0, 0, 'A', 1, 0, 0);
  ok(
    valid_preinit_status($rv), 
    'tb_set_cell_ex returns expected pre-init status'
  );

  $rv = tb_extend_cell(0, 0, 0x0301);
  ok(
    valid_preinit_status($rv),
    'tb_extend_cell returns expected pre-init status'
  );

  $rv = tb_set_cell_ex(0, 0, '', 0, 0, 0);
  ok(
    valid_preinit_status($rv),
    'tb_set_cell_ex handles empty cluster pre-init'
  );
};

subtest 'set-cell APIs after init' => sub {
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  my $rv = Termbox::init_cellbuf();
  plan skip_all => 'init_cellbuf failed in this environment'
    if $rv != TB_OK();

  plan tests => 11;

  $rv = tb_set_cell(0, 0, 'A', 0, 0);
  is($rv, TB_OK(), 'tb_set_cell writes one codepoint');

  my $cells;
  {
    local $SIG{__WARN__} = sub { };
    $cells = tb_cell_buffer();
  }
  is($cells->[0]->ch, ord('A'), 'tb_set_cell stores expected text');

  $rv = tb_set_cell_ex(0, 0, pack('U*', ord('A'), 0x0301), 2, 0, 0);
  is($rv, TB_OK(), 'tb_set_cell_ex writes a cluster');
  is($cells->[0][0], "A\x{0301}", 'tb_set_cell_ex stores combined grapheme');
  is_deeply(
    $cells->[0]->ech, 
    [ ord('A'), 0x0301 ], 
    'tb_set_cell_ex stores expected codepoints'
  );

  $rv = tb_extend_cell(0, 0, chr 0x0327);
  is($rv, TB_OK(), 'tb_extend_cell appends one codepoint');
  is(
    $cells->[0][0],
    "A\x{0301}\x{0327}",
    'tb_extend_cell appends to existing grapheme'
  );
  is_deeply(
    $cells->[0]->ech, 
    [ ord('A'), 0x0301, 0x0327 ], 
    'tb_set_cell_ex appends expected codepoints'
  );

  $rv = tb_set_cell_ex(0, 0, '', 0, 0, 0);
  is($rv, TB_OK(), 'tb_set_cell_ex accept empty cluster');
  is($cells->[0]->ch, 0, 
    'tb_set_cell_ex with empty cluster sets cell to null character');
  {
    local $SIG{__WARN__} = sub { };
    is(Termbox::tb_deinit(), TB_OK(), 'tb_deinit succeeds');
  }
};

subtest 'tb_get_cell basic behaviour' => sub {
  plan tests => 4;
  my $cell;

  # not initialized
  is(
    tb_get_cell(1, 1, 0, \$cell),
    TB_ERR_NOT_INIT,
    'fails when not initialized'
  );

  # initialized
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{front} = cellbuf->new();
  $Termbox::global->{back} = cellbuf->new();
  $Termbox::global->{front}->init(2, 2);
  $Termbox::global->{back}->init(2, 2);
  is(
    tb_get_cell(1, 1, 0, \$cell),
    TB_OK,
    'tb_get_cell returns TB_OK'
  );
  isa_ok(
    $Termbox::global->{front},
    'cellbuf',
    'cell stored in front buffer'
  );
  is(
    tb_get_cell(99, 99, 0, \$cell),
    TB_ERR_OUT_OF_BOUNDS,
    'out of bounds returns TB_ERR_OUT_OF_BOUNDS'
  );
};

done_testing();
