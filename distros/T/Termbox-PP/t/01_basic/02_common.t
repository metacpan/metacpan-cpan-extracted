use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :return :event :colors );
}

subtest 'global default shape after tb_reset' => sub {
  plan tests => 22;

  is(Termbox::tb_reset(), TB_OK(), 'tb_reset returns TB_OK');

  my $g = $Termbox::global;
  is(ref($g), 'HASH', 'global is a hash-ref');

  is($g->{initialized}, 0, 'initialized defaults to 0');
  is($g->{width}, -1, 'width defaults to -1');
  is($g->{height}, -1, 'height defaults to -1');
  is($g->{cursor_x}, -1, 'cursor_x defaults to -1');
  is($g->{cursor_y}, -1, 'cursor_y defaults to -1');
  is($g->{last_x}, -1, 'last_x defaults to -1');
  is($g->{last_y}, -1, 'last_y defaults to -1');

  is($g->{fg}, TB_DEFAULT(), 'fg defaults to TB_DEFAULT');
  is($g->{bg}, TB_DEFAULT(), 'bg defaults to TB_DEFAULT');
  is($g->{input_mode}, TB_INPUT_ESC(), 
    'input_mode defaults to TB_INPUT_ESC');
  is($g->{output_mode}, TB_OUTPUT_NORMAL(), 
    'output_mode defaults to TB_OUTPUT_NORMAL');

  is(ref($g->{resize_pipefd}), 'ARRAY', 'resize_pipefd is an array-ref');
  is(scalar(@{ $g->{resize_pipefd} }), 2, 'resize_pipefd has two entries');
  is($g->{resize_pipefd}[0], -1, 'resize_pipefd[0] defaults to -1');
  is($g->{resize_pipefd}[1], -1, 'resize_pipefd[1] defaults to -1');

  is(ref($g->{caps}), 'ARRAY', 'caps is an array-ref');
  is(scalar(@{ $g->{caps} }), Termbox::TB_CAP__COUNT(), 
    'caps has TB_CAP__COUNT entries');

  is(ref($g->{back}), 'cellbuf', 'back buffer is a cellbuf');
  is(ref($g->{front}), 'cellbuf', 'front buffer is a cellbuf');
  is(ref($g->{cap_trie}), 'captrie', 'cap_trie is a captrie');
};

subtest 'tb_last_errno tracks global error slot' => sub {
  plan tests => 2;

  is(Termbox::tb_reset(), TB_OK(), 'tb_reset returns TB_OK');
  $Termbox::global->{last_errno} = 123;
  is(Termbox::tb_last_errno(), 123, 'tb_last_errno reads global->{last_errno}');
};

subtest 'tb_reset preserves ttyfd_open only' => sub {
  plan tests => 5;

  local $Termbox::global->{initialized} = 1;
  $Termbox::global->{ttyfd_open} = 1;
  $Termbox::global->{width} = 80;
  $Termbox::global->{height} = 24;

  is(Termbox::tb_reset(), TB_OK(), 'tb_reset returns TB_OK');
  is($Termbox::global->{ttyfd_open}, 1, 'tb_reset preserves ttyfd_open');
  is($Termbox::global->{initialized}, 0, 'tb_reset clears initialized');
  is($Termbox::global->{width}, -1, 'tb_reset resets width');
  is($Termbox::global->{height}, -1, 'tb_reset resets height');
};

done_testing();
