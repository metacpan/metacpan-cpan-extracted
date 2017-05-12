#!/usr/bin/perl

use constant SIZE => 3;

BEGIN {
    $| = 1;
    print "1..10\n";
    eval "use Proc::Queue size => SIZE, ':all'";
    print "not " if $@;
    print "ok 1\n";
}

# test that not more than SIZE children are running at the same time
$ok=1;
foreach (1..5) {
  my $f=fork;
  if(defined ($f) and $f==0) {
    sleep 1;
    exit(0)
  }
  $ok=0 if running_now > SIZE;
}
1 while wait != -1;
print $ok ? "ok 2\n" : "not ok 2\n";

# test that fork_now ignores SIZE. Theorically this test suffers from
# a race condition and could fail, but it would also mean that your machine
# is not able to fork 3 processes in 2 seconds so upgrade
# now!

$ok=0;
foreach (1..10) {
  my $f=fork_now;
  if(defined ($f) and $f==0) {
    sleep 2;
    exit(0)
  }
  $ok=1 if running_now > SIZE;
}
print $ok ? "ok 3\n" : "not ok 3\n";

# test run_back and test_all_ok
$ok=1;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=0 if running_now > SIZE
}
$ok&&=all_exit_ok(@pids);
print $ok ? "ok 4\n" : "not ok 4\n";

# test run_back and test_all_ok again
$ok=1;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=0 if running_now > SIZE
}
push @pids, run_back_now { exit(1) };

$ok&&=!all_exit_ok(@pids);
print $ok ? "ok 5\n" : "not ok 5\n";

# test waitpid
$ok=1;
$pid=fork;
if (defined $pid and $pid==0) {
  sleep 1;
  exit(0);
}

print ($pid==waitpid($pid,0) ? "ok 6\n" : "not ok 6\n" );

#testing weights
Proc::Queue::size(4);
Proc::Queue::weight(3);
# with this parameters at some point there should be 6 (weighted) processes running.
$ok=0;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=1 if running_now == 6;
}
$ok&&=all_exit_ok(@pids);
print $ok ? "ok 7\n" : "not ok 7\n";

# ... but never more
$ok=1;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=0 if running_now > 6;
}
$ok&&=all_exit_ok(@pids);
print $ok ? "ok 8\n" : "not ok 8\n";


# testing allow_excess(0)
Proc::Queue::size(7);
Proc::Queue::allow_excess(0);

$ok=0;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=1 if running_now == 6;
}
$ok&&=all_exit_ok(@pids);
print $ok ? "ok 9\n" : "not ok 9\n";

# ... but never more
$ok=1;
@pids=();
foreach my $i (1..5) {
  push @pids, run_back {
    sleep 1;
    exit(0)
  };
  $ok=0 if running_now > 6;
}
$ok&&=all_exit_ok(@pids);
print $ok ? "ok 10\n" : "not ok 10\n";
