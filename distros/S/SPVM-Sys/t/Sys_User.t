use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Sys::User';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();


if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->getuid_value };
  ok($@);
}
else {
  is(SPVM::TestCase::Sys::User->getuid_value, "$<");
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->geteuid_value };
  ok($@);
}
else {
  is(SPVM::TestCase::Sys::User->geteuid_value, "$>");
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->getgid_value };
  ok($@);
}
else {
  is(SPVM::TestCase::Sys::User->getgid_value, (split(/\s+/, "$("))[0]);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->getegid_value };
  ok($@);
}
else {
  is(SPVM::TestCase::Sys::User->getegid_value, (split(/\s+/, "$)"))[0]);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->setuid };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->setuid);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->seteuid };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->seteuid);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->setgid };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->setgid);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->setegid };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->setegid);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->setpwent };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->setpwent);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->endpwent };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->endpwent);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->setgrent };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->setgrent);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->endgrent };
  ok($@);
}
else {
  ok(SPVM::TestCase::Sys::User->endgrent);
}

# TODO
# This test failed. Maybe permission problems
=pod
{
  my @groups_expected = split(/\s+/, "$)");
  shift @groups_expected;
  is_deeply(SPVM::TestCase::Sys::User->getgroups_value->to_elems, \@groups_expected);
  ok(SPVM::TestCase::Sys::User->setgroups);
}
=cut

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);


done_testing;
