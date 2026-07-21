use 5.010;
use strict;
use warnings;

use Test::More;
use POSIX ();

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :event :return );
}

# Mock out internal functions to isolate the code paths under test. 
no warnings 'redefine';

local *Termbox::update_term_size  = sub { TB_OK };
local *Termbox::resize_cellbufs   = sub { TB_OK };
local *Termbox::extract_esc       = sub { TB_ERR };
local *Termbox::tb_utf8_char_length = sub { 1 };
local *Termbox::tb_utf8_char_to_unicode = sub {
  my ($out, $in) = @_;
  $$out = ord(substr($in,0,1));
};

# ---------------------------
note 'Testing extract_event';
# ---------------------------

subtest 'extract_event basic key handling' => sub {
  plan tests => 3;

  local $Termbox::global->{input_mode} = TB_INPUT_ESC;
  local $Termbox::global->{inbuf}       = "a";

  my $ev = Termbox::Event->new();

  is(
    Termbox::extract_event($ev),
    TB_OK,
    'extract_event returns TB_OK'
  );

  is($ev->{ch}, ord('a'), 'character extracted');
  is($ev->{type}, TB_EVENT_KEY, 'event type is KEY');
};

# ------------------------
note 'Testing wait_event';
# ------------------------

subtest 'wait_event fast path from buffer' => sub {
  plan tests => 2;

  my ($tty_r, $tty_w) = POSIX::pipe();
  my ($rsz_r, $rsz_w) = POSIX::pipe();

  local $Termbox::global->{inbuf}          = "b";
  local $Termbox::global->{rfd}            = $tty_r;
  local $Termbox::global->{resize_pipefd}  = [ $rsz_r, $rsz_w ];

  my $ev = Termbox::Event->new();
  is(
    Termbox::wait_event($ev, 0), 
    TB_OK,
    'wait_event returns TB_OK from buffered input'
  );
  is($ev->{ch}, ord('b'), 'buffered key extracted');

  # Close fds
  POSIX::close($_) for ($tty_r, $tty_w, $rsz_r, $rsz_w);
};

subtest 'wait_event resize event' => sub {
  plan skip_all => 'not supported on Windows' if $^O eq 'MSWin32';
  plan tests => 3;

  my ($tty_r, $tty_w) = POSIX::pipe();
  my ($rsz_r, $rsz_w) = POSIX::pipe();

  local $Termbox::global->{rfd}           = $tty_r;
  local $Termbox::global->{resize_pipefd} = [ $rsz_r, $rsz_w ];
  local $Termbox::global->{width}         = 80;
  local $Termbox::global->{height}        = 24;
  local $Termbox::global->{inbuf}         = '';

  # Trigger resize notification
  POSIX::write($rsz_w, "1234", 4);

  my $ev = Termbox::Event->new();

  is(
    Termbox::wait_event($ev, 10),
    TB_OK,
    'wait_event returns TB_OK on resize'
  );

  is($ev->{type}, TB_EVENT_RESIZE, 'event type is RESIZE');
  is_deeply(
    [ $ev->{w}, $ev->{h} ],
    [ 80, 24 ],
    'resize dimensions propagated'
  );

  # Close fds
  POSIX::close($_) for ($tty_r, $tty_w, $rsz_r, $rsz_w);
};

done_testing;
