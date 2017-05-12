use strict;
use warnings;
use Test::More;

use Errno qw(ENOENT);
use Process::Status;

subtest "status_code == 31488" => sub {
  my $status = Process::Status->new(123 << 8);

  is($status->exitstatus, 123, "exit status 123");
  ok(! $status->signal,        "caught no signal");
  ok(! $status->cored,         "did not dump core");

  is_deeply(
    $status->as_struct,
    { status_code => 31488, exitstatus => 123, cored => 0 },
    "->as_struct is as expected",
  );

  is($status->as_string, "exited 123", "->as_string is as expected");
};

subtest "status_code == 395" => sub {
  my $status = Process::Status->new(395);

  is($status->exitstatus,  1, "exit status 1");
  is($status->signal,     11, "caught signal 11");
  ok($status->cored,          "dumped core");

  is_deeply(
    $status->as_struct,
    { status_code => 395, exitstatus => 1, signal => 11, cored => 1 },
    "->as_struct is as expected",
  );

  is(
    $status->as_string,
    "exited 1, caught SIGSEGV; dumped core",
    "->as_string is as expected",
  );
};

subtest "status_code == -1" => sub {
  $! = ENOENT;
  my $num = 0+$!;
  my $str = "$!";

  my $status = Process::Status->new(-1);

  undef $!;

  is($status->exitstatus, -1, "exit status 1");
  ok(! $status->signal,       "didn't catch a signal");
  ok(! $status->cored,        "didn't dump core");

  is_deeply(
    $status->as_struct,
    { status_code => -1, strerror => $str, errno => $num },
    "->as_struct is as expected",
  );

  is(
    $status->as_string,
    qq{did not run; \$? was -1, \$! was "$str" (errno $num)},
    "->as_string is as expected",
  );
};

done_testing;
