use Mojo::Base -strict;
use Mojo::Alien::rollup;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_ROLLUP=1' unless $ENV{TEST_ROLLUP} or $ENV{TEST_ALL};
note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;
sub maybe (&) { local $TODO = 'MOJO_NPM_CLEAN=0' unless $ENV{MOJO_NPM_CLEAN}; shift->(); }

subtest 'basic' => sub {
  my $rollup = Mojo::Alien::rollup->new;
  is $rollup->mode, 'development', 'mode';

  isa_ok $rollup->npm, 'Mojo::Alien::npm', 'npm';
  is $rollup->npm->config->dirname, $rollup->config->dirname, 'npm config location' or diag $rollup->config;

  isa_ok $rollup->config, 'Mojo::File', 'config';
  maybe { ok !-e $rollup->config, 'config' };

  is $rollup->pid, 0, 'pid';
  is $rollup->stop, $rollup, 'stop';
};

subtest 'build' => sub {
  my $rollup = Mojo::Alien::rollup->new;

  $rollup->config->dirname->child(qw(assets))->make_path->child('index.js')->spurt("console.log(42);\n");
  is $rollup->build, $rollup, 'build';

  local $rollup->{binary} = '/no/such/bin/rollup';
  eval { $rollup->build };
  like $@, qr(Can't run.*rollup), 'invalid binary';
};

subtest 'watch' => sub {
  my $rollup = Mojo::Alien::rollup->new;
  ok !$rollup->pid, 'no pid';

  is $rollup->watch, $rollup, 'watch';

  note 'wating for process to watch';
  1 until $rollup->pid;

  eval { $rollup->build };
  like $@, qr{Can't call build}, 'cannot call watch and then build';

  note 'stop running process';
  is $rollup->stop, $rollup, 'stop';
  ok !$rollup->pid, 'stopped';

  local $rollup->{binary} = '/no/such/bin/rollup';
  eval { $rollup->watch };
  like $@, qr(Can't run.*rollup), 'invalid binary';
};

done_testing;
