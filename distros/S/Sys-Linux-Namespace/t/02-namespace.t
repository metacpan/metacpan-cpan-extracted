BEGIN {
  $ENV{TMPDIR} = 't/tmp/'
}

use Test::More;
use Test::SharedFork;

use Sys::Linux::Namespace;
$Sys::Linux::Namespace::debug = 1;

SKIP: {
  skip "Need to be root to run test", 5 unless $< == 0;
  ok(my $namespace = Sys::Linux::Namespace->new(private_tmp => 1), "Setup object");

  my $ret = $namespace->run(code => sub {
      is_deeply([glob "/tmp/*"], [], "No files present in /tmp");
  });

  ok(my $pid_ns = Sys::Linux::Namespace->new(private_tmp => 1, private_pid => 1), "Setup pid object");

  $ret = $pid_ns->run(code => sub {
    is($$, 1, "We're init");
    is_deeply([grep {m|/proc/\d+/|} glob '/proc/*/'], ['/proc/1/'], "Only /proc/1/ exists");
  });

  # namespace process exited cleanly
  ok($ret == 0, "run code in sandbox");

  alarm(5);
  $pid_ns->run(code => sub {
    is($$, 1, "Alarmed init");
    sleep(10);
    fail("signal propogation didn't happen");
  });

  alarm(5);
  $pid_ns->run(code => sub {
    is($$, 1, "Second alarmed init");
  
    my $pid = fork();

    isnt($pid, undef, "Fork succeeded");
    if (!$pid) {
      sleep(30); # sleep a gigantic amount of time in the child
      # We should never happen here, because our parent PID 1 should be destroyed by the kernel first
      fail("Child of PID 1 lived, $$");
    } else {
      waitpid($pid, 0); # wait forever
      fail("PID 1 never got reaped");
    }
  });

  ok($namespace->setup(), "Setup namespace in current process");
  is_deeply([glob "/tmp/*"], [], "No files present in /tmp");
}

done_testing;
