use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use POSIX q(:sys_wait_h);

use SPVM 'Sys::Process';

use SPVM 'TestCase::Sys::Process';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->fork };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->fork);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->getpriority(0, 0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->getpriority);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->setpriority(0, 0, 0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->setpriority);
}

if ($^O eq 'MSWin32') {
  eval { my $status = -1; SPVM::Sys::Process->wait(\$status) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->wait);
}

if ($^O eq 'MSWin32') {
  eval { my $status = -1; SPVM::Sys::Process->waitpid(0, \$status, 0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->waitpid);
}


ok(SPVM::TestCase::Sys::Process->system);

# The exit method
{
  {
    my $exit_success_program = "$^X -Mblib $FindBin::Bin/exit_success.pl";
    my $status = system($exit_success_program);
    ok($status >> 8 == POSIX::EXIT_SUCCESS);
  }
  {
    my $exit_failure_program = "$^X -Mblib $FindBin::Bin/exit_failure.pl";
    my $status = system($exit_failure_program);
    ok($status >> 8 == POSIX::EXIT_FAILURE);
  }
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->pipe(undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->pipe);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->getpgid(0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->getpgid);
  is(getpgrp(0), SPVM::Sys::Process->getpgid(0));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->setpgid(0, 0) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->setpgid);
}

{
  ok(SPVM::TestCase::Sys::Process->getpid);
  is($$, SPVM::Sys::Process->getpid);
}
if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Process->getppid };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Process->getppid);
  is(getppid(), SPVM::Sys::Process->getppid);
}

# The execv method
{
  {
    my $exit_success_program = "$^X -Mblib $FindBin::Bin/execv_success.pl";
    my $output = `$exit_success_program`;
    is($output, 'Hello abc');
    ok($? >> 8 == POSIX::EXIT_SUCCESS);
  }
}

# The exit status
unless ($^O eq 'MSWin32') {

  is(WIFEXITED(0), SPVM::Sys::Process->WIFEXITED(0));
  is(WEXITSTATUS(0), SPVM::Sys::Process->WEXITSTATUS(0));
  is(WIFSIGNALED(0), SPVM::Sys::Process->WIFSIGNALED(0));
  is(WTERMSIG(0), SPVM::Sys::Process->WTERMSIG(0));
  is(WIFSTOPPED(0), SPVM::Sys::Process->WIFSTOPPED(0));
  is(WSTOPSIG(0), SPVM::Sys::Process->WSTOPSIG(0));
  
  # Non-POSIX
  SPVM::Sys::Process->WIFCONTINUED(0);
  SPVM::Sys::Process->WCOREDUMP(0);
}

warn "[Test Output]sleep";

ok(SPVM::TestCase::Sys::Process->sleep);

warn "[Test Output]usleep";

ok(SPVM::TestCase::Sys::Process->usleep);

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
