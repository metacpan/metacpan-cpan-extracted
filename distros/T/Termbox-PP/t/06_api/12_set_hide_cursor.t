use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return TB_CAP_SHOW_CURSOR TB_CAP_HIDE_CURSOR );
}

# ------------------------------------
note 'Set the position of the cursor';
# ------------------------------------

subtest 'tb_set_cursor' => sub {
  plan tests => 6;
  is(tb_set_cursor(1,1), TB_ERR_NOT_INIT, 'not initialized');

  # Mock bytebuf_puts and send_cursor_if to verify tb_set_cursor
  my @calls;
  no warnings 'redefine';
  local *Termbox::bytebuf_puts = sub {
    push @calls, $_[1];
    return TB_OK;
  };
  local *Termbox::send_cursor_if = sub {
    push @calls, @_;
    return TB_OK;
  };

  # Initialize global state to allow tb_set_cursor to proceed
  local $Termbox::global->{initialized} = 1;
  local $Termbox::global->{cursor_x}    = -1;
  local $Termbox::global->{cursor_y}    = -1;
  local $Termbox::global->{out}         = '';
  local $Termbox::global->{caps}[TB_CAP_SHOW_CURSOR] = 'SHOW';
  local $Termbox::global->{caps}[TB_CAP_HIDE_CURSOR] = 'HIDE';

  # Test setting cursor to a valid position
  is(tb_set_cursor(5, 6), TB_OK, 'tb_set_cursor returns TB_OK');
  is($calls[0], 'SHOW', 'show cursor capability emitted');
  is_deeply([@calls[1..2]], [5..6], 'send_cursor_if called');
  is($Termbox::global->{cursor_x}, 5, 'cursor_x updated');
  is($Termbox::global->{cursor_y}, 6, 'cursor_y updated');
};

subtest 'tb_hide_cursor' => sub {
  plan tests => 4;

  # Mock bytebuf_puts to verify tb_hide_cursor
  my @calls;
  no warnings 'redefine';
  local *Termbox::bytebuf_puts = sub {
    push @calls, $_[1];
    return TB_OK;
  };

  # Initialize global state to allow tb_hide_cursor to proceed
  local $Termbox::global->{initialized} = 1;
  local $Termbox::global->{cursor_x}    = 3;
  local $Termbox::global->{cursor_y}    = 4;
  local $Termbox::global->{out}         = '';
  local $Termbox::global->{caps}[TB_CAP_HIDE_CURSOR] = 'HIDE';

  # Test hiding the cursor
  is(tb_hide_cursor(), TB_OK, 'tb_hide_cursor returns TB_OK');
  is($calls[0], 'HIDE', 'hide cursor capability emitted');
  is($Termbox::global->{cursor_x}, -1, 'cursor_x reset');
  is($Termbox::global->{cursor_y}, -1, 'cursor_y reset');
};

done_testing;
