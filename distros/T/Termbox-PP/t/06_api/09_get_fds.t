use 5.010;
use strict;
use warnings;

use Test::More;

if ($^O eq 'MSWin32') {
  plan skip_all => 'Not available on Windows';
}

require_ok 'Termbox::PP';
use_ok 'Termbox', qw( :api :return );

# -----------------------------------------------
note 'Get fds that can be used with poll/select';
# -----------------------------------------------

subtest 'tb_get_fds returns tty and resize fds' => sub {
  plan tests => 4;

  is(
    tb_get_fds(\my $a, \my $b),
    TB_ERR_NOT_INIT(),
    'tb_get_fds fails when not initialized'
  );

  local $Termbox::global->{initialized}    = 1;
  local $Termbox::global->{rfd}            = 10;
  local $Termbox::global->{resize_pipefd}  = [ 20, 21 ];

  my ($ttyfd, $resizefd);
  is(tb_get_fds(\$ttyfd, \$resizefd), TB_OK(), 'tb_get_fds returns TB_OK');

  is($ttyfd,    10, 'tty fd returned');
  is($resizefd, 20, 'resize fd returned');
};

done_testing;
