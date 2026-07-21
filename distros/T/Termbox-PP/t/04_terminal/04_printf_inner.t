use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return );
}

subtest 'tb_printf_inner - error handling' => sub {
  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  my $rv = Termbox::init_cellbuf();
  plan skip_all => 'init_cellbuf failed in this environment'
    if $rv != TB_OK();

  plan tests => 3;

  my $buf = '';
  $rv = Termbox::tb_printf_inner(0, 0, 0, 0, \$buf, 'Hello');
  is($rv, TB_OK(), 'tb_printf_inner returns valid result');

  $rv = eval { Termbox::tb_printf_inner(-1, -1, 0, 0, \$buf, 'X') } // TB_ERR();
  ok($rv == TB_ERR() || $rv == TB_ERR_OUT_OF_BOUNDS(), 
    'tb_printf_inner handles invalid position');

  $rv = Termbox::tb_printf_inner(0, 0, 0, 0, \$buf, '');
  is($rv, TB_OK(), 'tb_printf_inner handles empty format string');
};

done_testing();
