#!perl

use Test::More;
use Test::Deep;
use Proc::PidChange ':all';
use Data::Dumper;

plan skip_all => 'No support for real-time notification of PID changes, POSIX::AtFork not found or not working'
  unless $Proc::PidChange::RT;


my %calls;
my $cb1 = sub { $calls{cb1}++ };
my $cb2 = sub { $calls{cb2}++ };
my $cb3 = sub { $calls{cb3}++ };

register_pid_change_callback($cb1, $cb2, $cb3, $cb2);
cmp_deeply(\%calls, {}, 'start with an empty call log');

pipe(my $reader, my $writer);
if (my $pid = fork()) {    ## parent
  close($writer);

  cmp_deeply(\%calls, {}, 'on parent, pid not changed, call log still empty');

  my $call_log = do { local $/; <$reader> };
  cmp_deeply(eval $call_log, { cb1 => 1, cb2 => 2, cb3 => 1 }, 'on child, callbacks were called');

  close($reader);
  waitpid($pid, 0);
}
else {                     ## child
  close($reader);
  check_current_pid();     ## should be a no-op with RT enabled
  print $writer Dumper(\%calls);
  close($writer);
  exit(0);
}


done_testing();
