use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Log::Log4perl::CommandLine ':all';
use Parallel::TaskExecutor ':all';
use Test2::IPC;
use Test2::V0;

{
  my $t = default_executor->run(sub { die 'foo' }, catch_error => 1);
  like(dies { $t->get() }, qr/Child command failed/);
}

{
  my $pid = fork;
  if (!defined $pid) {
    fail('Cannot fork a process');
  } elsif ($pid == 0) {
    # In the child task
    my $t = default_executor->run(sub { die 'foo' });
    eval { $t->wait() };
    sleep(1) while 1;  # Even with an eval, we never reach this point.
  } else {
    # In the parent task
    is(waitpid($pid, 0),  $pid, 'wait for the child to fail');
    # Ideally we would want to test ${^CHILD_ERROR_NATIVE} or $? but, for some
    # reasons that I don’t understand, they are always 0.
  }
}

done_testing;
