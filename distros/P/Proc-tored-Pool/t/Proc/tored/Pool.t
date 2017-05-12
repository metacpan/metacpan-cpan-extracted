use Test2::Bundle::Extended '!call';
use Path::Tiny;
use Proc::tored::Pool;

my $name = 'proc-tored-pool-test';
my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $a_args; my $a_count = 0;
my $s_args; my $s_count = 0;
my $f_args; my $f_count = 0;

sub reset_vars {
  undef $a_args;
  undef $s_args;
  undef $f_args;
  $a_count = 0;
  $s_count = 0;
  $f_count = 0;
}

my $pool = pool $name, in "$dir", capacity 4,
  on assignment, call { $a_args = [@_]; ++$a_count; },
  on success, call { $s_args = [@_]; ++$s_count; },
  on failure, call { $f_args = [@_]; ++$f_count; };

ok $pool, 'build';

subtest 'positive path' => sub {
  reset_vars();

  my $sent = process { 'foo' } $pool, 'id-foo';
  ok $sent, 'process';
  sync $pool;

  is $a_args, [$pool, 'id-foo'], 'assignment';
  is $s_args, [$pool, 'id-foo', 'foo'], 'success';
  is $f_args, undef, 'failure';
};

subtest 'failure' => sub {
  reset_vars();

  process { die 'bar' } $pool, 'id-bar';
  sync $pool;

  is $a_args, [$pool, 'id-bar'], 'assignment';
  is $s_args, undef, 'success';
  like $f_args, [$pool, 'id-bar', qr/bar/], 'failure';
};

subtest 'run' => sub {
  reset_vars();

  my $i = 0;

  run {
    if (++$i == 10) {
      stop $pool;
    }

    process { $i * 2 } $pool;
    return $i;
  } $pool;

  ok !(running $pool), '!is_running';
  is $i, 10, 'expected work completed';
  is $a_count, 10, 'assignment';
  is $s_count, 10, 'success';
  is $f_count, 0, 'failure';
};

done_testing;
