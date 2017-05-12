#!perl

use Test::More;
use Test::Deep;
BEGIN { $ENV{PROC_PIDCHANGE_NO_RT}++ }
use Proc::PidChange ':all';
use Data::Dumper;

my %calls;
my $cb1 = sub { $calls{cb1}++ };
my $cb2 = sub { $calls{cb2}++ };
my $cb3 = sub { $calls{cb3}++ };

register_pid_change_callback($cb1, $cb2, $cb3, $cb2);
cmp_deeply(\%calls, {}, 'start with an empty call log');

check_current_pid();
cmp_deeply(\%calls, {}, 'pid not changed, call log still empty');

pipe(my $reader, my $writer);
my $pid = fork();
check_current_pid();

if ($pid) {    ## parent
  close($writer);

  cmp_deeply(\%calls, {}, 'on parent, pid not changed, call log still empty');

  my $call_log = do { local $/; <$reader> };
  cmp_deeply(eval $call_log, { cb1 => 1, cb2 => 2, cb3 => 1 }, 'on child, callbacks were called');

  close($reader);
  waitpid($pid, 0);
}
else {         ## child
  check_current_pid();    ## second call is a no-op
  close($reader);
  print $writer Dumper(\%calls);
  close($writer);
  exit(0);
}


done_testing();
