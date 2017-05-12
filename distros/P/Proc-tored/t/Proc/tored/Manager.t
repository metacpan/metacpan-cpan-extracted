use Test2::Bundle::Extended;
use Path::Tiny 'path';
use Data::Dumper;
use Proc::tored::Manager;
use Proc::tored::Machine;

my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
skip_all 'could not create writable temp directory' unless -w $dir;

my $term = $dir->child("$$.term");


sub counter($\$%) {
  my ($proc, $acc, %flag) = @_;
  my $backstop = 10;
  my $count = 0;

  return sub {
    $$acc = ++$count;

    if ($count == $backstop) {
      $proc->stop;
      return;
    }

    if ($count == $backstop + 4) {
      die "backstop failed ($count)";
    }

    return $flag{$count}->($count)
      if $flag{$count};

    return 1;
  };
}

ok my $proc = Proc::tored::Manager->new(name => 'proc-tored-test-' . $$, dir => "$dir"), 'new';
is $proc->running_pid, 0, 'running_pid is 0 with no running process';
ok !$proc->is_running, '!is_running';
ok !$proc->is_stopped, '!is_stopped';
ok !$proc->is_paused, '!is_paused';

subtest 'start/stop' => sub {
  # Verify that stop flag
  $proc->clear_flags;
  ok !$proc->is_stopped, '!is_stopped';
  ok !$proc->start, '!start';
  ok $proc->stop, 'stop';
  ok $proc->is_stopped, 'is_stopped';
  ok $proc->start, 'start';
  ok !$proc->is_stopped, '!is_stopped';
};

subtest 'pause/resume' => sub {
  # Verify the pause flag
  $proc->clear_flags;
  ok !$proc->is_paused, '!is_paused';
  ok !$proc->resume, '!resume';
  ok $proc->pause, 'pause';
  ok $proc->is_paused, 'is_paused';
  ok $proc->resume, 'resume';
  ok !$proc->is_paused, '!is_paused';
};

subtest 'service' => sub {
  # Verify function of service()
  $proc->clear_flags;
  my $acc = 0;
  my $counter = counter $proc, $acc, 3 => sub { 0 };
  ok $proc->service($counter), 'run service';
  is $acc, 3, 'service callback was called expected number of times';
  ok !$proc->is_running, '!is_running';
  ok !$proc->is_stopped, '!is_stopped';
  ok !$proc->is_paused, '!is_paused';
};

subtest 'stop' => sub {
  # Verify function of stop()
  $proc->clear_flags;
  my $acc = 0;
  my $counter = counter $proc, $acc, 3 => sub { $proc->stop };
  ok $proc->service($counter), 'run service';
  ok !$proc->is_running, '!is_running';
  is $acc, 3, 'service self-terminates for touch file';
};

subtest 'cooperation' => sub {
  # Verify that a process will not start while another is running
  $proc->clear_flags;
  my $acc = 0;
  my $recursive_start = 0;

  my $counter = counter $proc, $acc,
    1 => sub {
      $proc->service(sub { $recursive_start = 1; return 0 });
      return 0;
    };

  ok $proc->service($counter), 'run service';
  ok !$proc->is_running, '!is_running';
  is $acc, 1, 'stopped when expected';
  ok !$recursive_start, 'second process did not start while first was running';
};

subtest 'precedence' => sub {
  # Verify precedence of stop over the pause flag (will die rather than pause)
  $proc->clear_flags;

  # Override the pause_sleep function to prevent actually pausing the service
  # and hanging up the test.
  no warnings 'redefine';
  local *Proc::tored::Machine::pause_sleep = sub { die 'service was paused' };

  my $acc = 0;
  my $counter = counter $proc, $acc,
    1 => sub {
      $proc->pause;
      $proc->stop;
      return 1;
    },
    2 => sub {
      return 0;
    };

  ok $proc->service($counter), 'run service';
  ok !$proc->is_running, '!is_running';
  is $acc, 1, 'stopped when expected';
};

SKIP: {
  skip 'signals not supported for MSWin32' if $^O eq 'MSWin32';
  $proc = Proc::tored::Manager->new(name => 'proc-tored-test-' . $$, dir => "$dir", trap_signals => ['INT']);
  $proc->clear_flags;

  subtest 'signals' => sub {
    # Verify posix signal trapping on supported architectures
    $proc->clear_flags;
    my $acc = 0;
    my $counter = counter $proc, $acc, 3  => sub { kill 'INT', $$ };

    like warning { $proc->service($counter) }, qr/Caught SIGINT/, 'service warned on signal';
    ok !$proc->is_running, '!is_running';
    is $acc, 3, 'stopped when expected';
  };
};

done_testing;
