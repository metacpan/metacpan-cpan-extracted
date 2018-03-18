use strict;
use warnings;

use Test::More;
use Sys::Linux::Syscall::Execve qw/execve/;
use POSIX qw/_exit/;

sub test_exec {
  my $cmd = shift;
  my @args = @_;

  if (!-x $cmd) {
    return 42;
  }

  my $pid = fork();

  die "Couldn't fork: $!" unless defined $pid;

  if ($pid) {
    waitpid $pid, 0;
    return $?>>8;
  } else {
    execve($cmd, @args);
    _exit 42; # shibboleet;
  }
}

my $ret = test_exec("/bin/true");
is($ret, 0, "Executed /bin/true");

$ret = test_exec("/bin/false");
is($ret, 1, "Executed /bin/false");

$ret = test_exec("/bin/echo", "foo", "bar", "baz");
is($ret, 0, "Echo test with args");

done_testing;
