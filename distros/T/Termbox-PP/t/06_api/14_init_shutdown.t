use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw( :api :return );
}

# Mock all internal helpers used by tb_init_rwfd
no warnings 'redefine';
local *Termbox::init_term_attrs        = sub { TB_OK };
local *Termbox::init_term_caps         = sub { TB_OK };
local *Termbox::init_cap_trie          = sub { TB_OK };
local *Termbox::init_resize_handler    = sub { TB_OK };
local *Termbox::send_init_escape_codes = sub { TB_OK };
local *Termbox::send_clear             = sub { TB_OK };
local *Termbox::update_term_size       = sub { TB_OK };
local *Termbox::init_cellbuf           = sub { TB_OK };
local *Termbox::tb_deinit = sub { $Termbox::global->{initialized} = 0 };

# POSIX helpers
local *POSIX::isatty = sub { 1 };

# ----------------------------------------------
note 'tb_init_rwfd / tb_init_fd / tb_init_file';
# ----------------------------------------------

subtest 'tb_init_rwfd success path' => sub {
SKIP: {
  plan tests => 3;

  local $Termbox::global->{initialized} = 0;
  my ($in, $out);
  my ($rfd, $wfd, $ttyfd);
  my $rv;

  if ($^O eq 'MSWin32') {
    require Fcntl;
    require Win32API::File;
    sysopen($in,  'CONIN$',  Fcntl::O_RDWR);
    sysopen($out, 'CONOUT$', Fcntl::O_RDWR);
    $rfd = Win32API::File::GetOsFHandle($in);
    $wfd = Win32API::File::GetOsFHandle($out);
    $ttyfd = $wfd;
    $rv = tb_init_rwfd(fileno($in), fileno($out));
    if ($rv == TB_ERR_WIN_UNSUPPORTED()) {
      skip "Windows VT mode unsupported on this OS", 3;
    }
  } 
  else {
    $rfd = 10;
    $wfd = 11;
    $ttyfd = $rfd;
    $rv = tb_init_rwfd($rfd, $wfd);
  }

  is($rv, TB_OK, 'tb_init_rwfd returns TB_OK');
  ok($Termbox::global->{initialized}, 'global initialized set');
  is_deeply(
    {
      rfd   => $Termbox::global->{rfd},
      wfd   => $Termbox::global->{wfd},
      ttyfd => $Termbox::global->{ttyfd},
    },
    {
      rfd   => $rfd,
      wfd   => $wfd,
      ttyfd => $ttyfd,
    },
    'file descriptors stored correctly'
  );
}};

subtest 'tb_init_fd delegates to tb_init_rwfd' => sub {
  plan tests => 3;

  is(Termbox::tb_reset(), TB_OK, 'tb_reset returns TB_OK');
  local $Termbox::global->{initialized} = 0;

  is(
    tb_init_fd(7),
    $^O eq 'MSWin32' ? TB_ERR_WIN_UNSUPPORTED() : TB_OK(),
    'tb_init_fd returns TB_ERR_WIN_UNSUPPORTED'
  );

  is(
    $Termbox::global->{rfd}, 
    $^O eq 'MSWin32' ? Win32API::File::INVALID_HANDLE_VALUE() : 7,
    'rfd == wfd == ttyfd'
  );
};

subtest 'tb_init_file already initialized' => sub {
  plan tests => 1;

  local $Termbox::global->{initialized} = 1;

  is(
    tb_init_file('/dev/tty'),
    TB_ERR_INIT_ALREADY,
    'tb_init_file fails when already initialized'
  );
};

# -----------------
note 'tb_shutdown';
# -----------------

subtest 'tb_shutdown basic behaviour' => sub {
  plan tests => 2;

  local $Termbox::global->{initialized} = 1;

  is(
    tb_shutdown(),
    TB_OK,
    'tb_shutdown returns TB_OK'
  );

  ok(
    !$Termbox::global->{initialized},
    'global initialized cleared'
  );
};

subtest 'tb_shutdown when not initialized' => sub {
  plan tests => 1;

  local $Termbox::global->{initialized} = 0;

  is(
    tb_shutdown(),
    TB_ERR_NOT_INIT,
    'tb_shutdown fails when not initialized'
  );
};

done_testing;
