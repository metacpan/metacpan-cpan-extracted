use Test2::Bundle::Extended;
use Path::Tiny;
use Proc::tored;

my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $name = 'proc-tored-test';

subtest 'param shortcuts' => sub {
  is [in 'foo', 'bar', 'baz'], [qw(dir foo bar baz)], 'in';
  is [trap ['foo'], 'bar', 'baz'], ['trap_signals', ['foo'], 'bar', 'baz'], 'trap_signals';
};

subtest 'service' => sub {
  my $proctor = service $name, in "$dir";
  $proctor->clear_flags;
  is ref $proctor, 'Proc::tored::Manager', 'expected class';
  is $proctor->name, $name, 'expected name';
  is $proctor->dir, "$dir", 'expected dir';

  my $pid;
  my $count = 0;
  my $stop = 4;

  run { $pid = running $proctor; ++$count < $stop } $proctor;

  is $count, $stop, 'expected work completed';
  is $pid, $$, 'expected pid while running';
  is 0, running $proctor, 'no running pid';
};

subtest 'stop' => sub {
  my $proctor = service $name, in "$dir";
  $proctor->clear_flags;
  my $count = 0;
  my $stop = 4;

  run { stop $proctor if ++$count == $stop; $count < 10 } $proctor;

  is $count, $stop, 'expected work completed';
  is running $proctor, 0, 'no running pid';
};

SKIP: {
  skip 'signals not supported for MSWin32' if $^O eq 'MSWin32';

  subtest 'signal' => sub {
    my $proctor = service $name, in "$dir", trap ['INT'];
    $proctor->clear_flags;

    is $proctor->trap_signals, ['INT'], 'trap_signals';

    my $count = 0;
    my $stop  = 4;

    like warning {
      run {
        if (++$count == $stop) {
          kill 'INT', $$;
        }
        $count < 10
      } $proctor;
    }, qr/Caught SIGINT/, 'expected warning on sigtrap';

    is $count, $stop, 'expected work completed';
    is running $proctor, 0, 'no running pid';
  };
};

done_testing;
