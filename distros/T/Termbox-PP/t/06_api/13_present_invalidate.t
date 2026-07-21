use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return );
}

# ---------------------------------------
note 'Test tb_present and tb_invalidate';
# ---------------------------------------

subtest 'tb_present basic render pass' => sub {
  plan tests => 2;

  # Mock cellbuf and output to verify tb_present
  my @calls;
  my $flushed_buffer = '';
  no warnings 'redefine';
  local *Termbox::bytebuf_flush = sub {
    push @calls, 'flush';
    return TB_OK;
  };
  local *Termbox::tb_wcwidth = sub { 1 };

  # Initialize global state to allow tb_present to proceed
  local $Termbox::global->{initialized} = 1;
  local $Termbox::global->{front}       = cellbuf->new();
  local $Termbox::global->{back}        = cellbuf->new();
  local $Termbox::global->{outbuf}      = '';
  $Termbox::global->{front}->init(1, 1);
  $Termbox::global->{back}->init(1, 1);

  # Test that tb_present calls the expected output functions
  is(tb_present(), TB_OK, 'tb_present returns TB_OK');
  ok(grep(/flush/,   @calls), 'bytebuf_flush was called');
};

subtest 'tb_invalidate' => sub {
  plan tests => 3;

  no warnings 'redefine';

  # success path
  local *Termbox::resize_cellbufs = sub { TB_OK };
  local $Termbox::global->{initialized} = 1;
  is(
    tb_invalidate(),
    TB_OK,
    'tb_invalidate returns TB_OK'
  );

  # error propagation
  local *Termbox::resize_cellbufs = sub { TB_ERR_RESIZE_IOCTL };
  is(
    tb_invalidate(),
    TB_ERR_RESIZE_IOCTL,
    'tb_invalidate propagates resize_cellbufs error'
  );

  # not initialized
  local $Termbox::global->{initialized} = 0;
  is(
    tb_invalidate(),
    TB_ERR_NOT_INIT,
    'tb_invalidate fails when not initialized'
  );
};

done_testing;
