use 5.010;
use strict;
use warnings;

use Test::More;
use POSIX ();

if ($^O eq 'MSWin32') {
  plan skip_all => 'Not available on Windows';
}

require_ok 'Termbox::PP';
use_ok 'Termbox', qw( :return );

# Signal number for window change (resize) on Unix
use constant SIGWINCH => 28;

# Minimal globals expected by the resize helpers
$Termbox::global = {
  resize_pipefd => undef,
  rfd           => undef,
  wfd           => undef,
  width         => 0,
  height        => 0,
  last_errno    => 0,
};

# -------------------------
note 'init_resize_handler';
# -------------------------

subtest 'init_resize_handler' => sub {
  plan tests => 4;

  my $rv = Termbox::init_resize_handler();
  is($rv, TB_OK(), 'returns TB_OK');

  ok(
    ref $Termbox::global->{resize_pipefd} eq 'ARRAY', 
    'resize_pipefd is arrayref'
  );
  is(scalar @{ $Termbox::global->{resize_pipefd} }, 2, 'pipe has two fds');

  is($SIG{WINCH}, \&Termbox::handle_resize, 'SIGWINCH handler installed');
};

# -------------------
note 'handle_resize';
# -------------------

subtest 'handle_resize writes signal to pipe' => sub {
  plan tests => 3;

  my ($rfd, $wfd) = POSIX::pipe();
  diag "Failed to create pipe: $!" unless defined $rfd && defined $wfd;
  $Termbox::global->{resize_pipefd} = [$rfd, $wfd];

  Termbox::handle_resize(SIGWINCH);

  my $buf = pack('i', 0);
  my $n = POSIX::read($rfd, $buf, length($buf));

  ok($n > 0, 'data written to pipe');
  is($n, length($buf), 'read exactly buffer length bytes');
  my $sig = unpack('i', $buf);
  is($sig, SIGWINCH, 'pipe contains binary signal value');
};

# ---------------------
note 'resize_cellbufs';
# ---------------------

{
  no warnings qw( redefine once );
  local *Termbox::cellbuf_resize = sub { TB_OK() };
  local *Termbox::cellbuf_clear  = sub { TB_OK() };
  local *Termbox::send_clear     = sub { TB_OK() };
  subtest 'resize_cellbufs success path' => sub {
    plan tests => 1;
    is(Termbox::resize_cellbufs(), TB_OK(), 'returns TB_OK');
  };

  local *Termbox::cellbuf_resize = sub { TB_ERR_RESIZE_IOCTL() };
  subtest 'resize_cellbufs propagates error' => sub {
    plan tests => 1;
    is(
      Termbox::resize_cellbufs(),
      TB_ERR_RESIZE_IOCTL(),
      'propagates first error'
    );
  };
}

# ------------------------------
note 'update_term_size_via_esc';
# ------------------------------

subtest 'update_term_size_via_esc parses escape response' => sub {
  plan tests => 3;

  my ($rfd, $wfd) = POSIX::pipe();
  $Termbox::global->{rfd} = $rfd;
  $Termbox::global->{wfd} = $wfd;

  # Simulate terminal response: ESC [ 24 ; 80 R
  my $resp = "\e[24;80R";
  POSIX::write($wfd, $resp, length($resp));

  my $rv = Termbox::update_term_size_via_esc();

  is($rv, TB_OK(), 'returns TB_OK');
  is($Termbox::global->{width},  80, 'width parsed correctly');
  is($Termbox::global->{height}, 24, 'height parsed correctly');
};

# ----------------------
note 'update_term_size';
# ----------------------

subtest 'update_term_size without tty is a no-op' => sub {
  plan tests => 1;
  $Termbox::global->{ttyfd} = -1;

  is(
    Termbox::update_term_size(),
    TB_OK(),
    'update_term_size is a no-op without tty'
  );
};
done_testing;
