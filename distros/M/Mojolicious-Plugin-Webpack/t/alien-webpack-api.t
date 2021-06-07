use Mojo::Base -strict;
use Mojo::Alien::webpack;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_WEBPACK=1' unless $ENV{TEST_WEBPACK} or $ENV{TEST_ALL};
note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;
sub maybe (&) { local $TODO = 'MOJO_NPM_CLEAN=0' unless $ENV{MOJO_NPM_CLEAN}; shift->(); }

subtest 'basic' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  is $webpack->mode, 'development', 'mode';

  isa_ok $webpack->npm, 'Mojo::Alien::npm', 'npm';
  is $webpack->npm->config->dirname, $webpack->config->dirname, 'npm config location' or diag $webpack->config;

  isa_ok $webpack->config, 'Mojo::File', 'config';
  maybe { ok !-e $webpack->config, 'config' };

  is $webpack->pid, 0, 'pid';
  is $webpack->stop, $webpack, 'stop';
};

subtest 'build' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  is $webpack->build, $webpack, 'build';

  local $webpack->{binary} = '/no/such/bin/webpack';
  eval { $webpack->build };
  like $@, qr(Can't run.*webpack), 'invalid binary';
};

subtest 'watch' => sub {
  my $webpack = Mojo::Alien::webpack->new;
  ok !$webpack->pid, 'no pid';

  is $webpack->watch, $webpack, 'watch';

  note 'wating for process to watch';
  1 until $webpack->pid;

  eval { $webpack->build };
  like $@, qr{Can't call build}, 'cannot call watch and then build';

  note 'stop running process';
  is $webpack->stop, $webpack, 'stop';
  ok !$webpack->pid, 'stopped';

  local $webpack->{binary} = '/no/such/bin/webpack';
  eval { $webpack->watch };
  like $@, qr(Can't run.*webpack), 'invalid binary';
};

done_testing;
