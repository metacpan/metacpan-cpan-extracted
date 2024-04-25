use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Parallel::TaskExecutor;
use Test2::IPC;
use Test2::V0;

sub new {
  return Parallel::TaskExecutor->new(@_);
}

{
  pipe my $fi1, my $fo1;  # from parent to child
  pipe my $fi2, my $fo2;  # from child to parent
  my $t = new(max_parallel_tasks => 4)->run(sub {
    close $fo1;
    close $fi2;
    my $v = <$fi1>;
    die "Invalid value: -->${v}<--" unless $v eq "signal\n";
    close $fi1;
    print $fo2 "test\n";
    close $fo2;
  });
  close $fi1;
  close $fo2;
  print $fo1 "signal\n";
  close $fo1;
  my $r = <$fi2>;
  close $fi2;
  is($r, "test\n");
}

{
  pipe my $fi, my $fo;  # from child to parent
  new()->run_now(sub {
    close $fi;
    print $fo "test\n";
    close $fo;
  });
  close $fo;
  my $r = <$fi>;
  close $fi;
  is($r, "test\n");
}

{
  my $data = new()->run_now(sub {
    return 'test';
  });
  is($data, 'test');
}

{
  my @data = new()->run_now(sub {
    return qw(1 2 3);
  });
  is(\@data, [qw(1 2 3)]);
}


{
  my $task = new()->run(sub {
    return 'test';
  });
  $task->wait();
  is($task->data(), 'test');
}

{
  pipe my $fi, my $fo;  # from parent to child
  my $task = new()->run(sub {
    close $fo;
    <$fi>;
  });
  close $fi;
  is ($task->running(), T());
  like(dies { $task->data() }, qr/still running task/);
  close $fo;
  $task->wait();
  is ($task->running(), F());
}

{
  pipe my $fi, my $fo;  # from parent to child
  # This never returns, but the task is still processed correctly.
  my $task = new()->run(sub {
    close $fo;
    <$fi>;
    exec $^X, "-e", "use Time::HiRes 'usleep'; usleep(1000)";
  });
  close $fi;
  is ($task->running(), T());
  close $fo;
  $task->wait();
  is ($task->running(), F());
}

# Signal handling by the pseudo-processes under Windows is not completely
# predictable. So we don’t execute these tests under Windows.
unless ($^O eq 'MSWin32') {
  {
    my $task = new()->run(sub {
      sleep 1 while 1;
    }, catch_error => 1);
    kill 'INT', $task->pid();
    $task->wait();
    is ($task->running(), F());
    like(dies {$task->data()}, qr/failed/);
  }

  {
    my $mosi = IO::Pipe->new();
    my $task = new()->run(sub {
      $mosi->reader();
      $mosi->read(my $buf, 1);
    }, SIG => { INT => 'IGNORE'});
    $mosi->writer();
    kill 'INT', $task->pid();
    is ($task->running(), T());
    $mosi->close();
    $task->wait();
    is ($task->running(), F());
  }
}

done_testing;
