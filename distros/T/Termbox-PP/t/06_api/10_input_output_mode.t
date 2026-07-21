use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :event :return );
}

# Mock low-level output helpers
no warnings 'redefine';
local *Termbox::bytebuf_puts  = sub { TB_OK() };
local *Termbox::bytebuf_flush = sub { TB_OK() };

# ---------------------------------------------------------
note 'Set input mode for escape handling and mouse events';
# ---------------------------------------------------------

subtest 'tb_set_input_mode basic behaviour' => sub {
  plan tests => 3;

  local $Termbox::global->{initialized} = 1;
  local $Termbox::global->{input_mode}  = TB_INPUT_ESC();
  local $Termbox::global->{outbuf}       = '';
  local $Termbox::global->{wfd}          = 1;

  is(
    tb_set_input_mode(TB_INPUT_CURRENT()),
    TB_INPUT_ESC(),
    'TB_INPUT_CURRENT returns current mode'
  );

  ok(
    $Termbox::global->{input_mode} & TB_INPUT_ESC(),
    'ESC bit is set'
  );

  is(
    tb_set_input_mode(TB_INPUT_MOUSE()),
    TB_OK(),
    'mouse mode accepted'
  );
};

# ----------------------------------------
note 'Set output mode for color handling';
# ----------------------------------------

subtest 'tb_set_output_mode basic behaviour' => sub {
  plan tests => 4;

  local $Termbox::global->{initialized} = 1;
  local $Termbox::global->{output_mode} = TB_OUTPUT_NORMAL();
  local $Termbox::global->{fg}          = 1;
  local $Termbox::global->{bg}          = 2;

  is(
    tb_set_output_mode(TB_OUTPUT_CURRENT()),
    TB_OUTPUT_NORMAL(),
    'TB_OUTPUT_CURRENT returns current mode'
  );

  is(
    tb_set_output_mode(TB_OUTPUT_256()),
    TB_OK(),
    'TB_OUTPUT_256 accepted'
  );

  is(
    $Termbox::global->{output_mode},
    TB_OUTPUT_256,
    'output mode updated'
  );

  my $rv = eval { tb_set_output_mode(-1) } // TB_ERR;
  is(
    $rv,
    TB_ERR,
    'invalid output mode rejected'
  );
};

done_testing;
