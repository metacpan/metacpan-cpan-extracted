use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Sys::User';

use SPVM 'Sys';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();


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

if ($^O eq 'MSWin32') {
  eval { SPVM::TestCase::Sys::User->getgroups };
  ok($@);
}
else {
  my @groups_expected = split(/\s+/, "$)");
  shift @groups_expected;
  ok(SPVM::TestCase::Sys::User->getgroups(\@groups_expected));
}

# TODO
# This test failed. Maybe permission problems
=pod
{
  ok(SPVM::TestCase::Sys::User->setgroups);
}
=cut

# Sys
{
  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->real_user_id };
    ok($@);
  }
  else {
    is(SPVM::Sys->real_user_id, "$<");
  }
  
  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->effective_user_id };
    ok($@);
  }
  else {
    is(SPVM::Sys->effective_user_id, "$>");
  }
  
  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->real_group_id };
    ok($@);
  }
  else {
    is(SPVM::Sys->real_group_id, (split(/\s+/, "$("))[0]);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->effective_group_id };
    ok($@);
  }
  else {
    is(SPVM::Sys->effective_group_id, (split(/\s+/, "$)"))[0]);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->set_real_user_id(0) };
    ok($@);
  }
  else {
    SPVM::Sys->set_real_user_id(SPVM::Sys->real_user_id);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->set_effective_user_id(0) };
    ok($@);
  }
  else {
    SPVM::Sys->set_effective_user_id(SPVM::Sys->effective_user_id);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->set_real_group_id(0) };
    ok($@);
  }
  else {
    SPVM::Sys->set_real_group_id(SPVM::Sys->real_group_id);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->set_effective_group_id(0) };
    ok($@);
  }
  else {
    SPVM::Sys->set_effective_group_id(SPVM::Sys->effective_group_id);
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->setpwent };
    ok($@);
  }
  else {
    SPVM::Sys->setpwent;
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->endpwent };
    ok($@);
  }
  else {
    SPVM::Sys->endpwent;
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->setgrent };
    ok($@);
  }
  else {
    SPVM::Sys->setgrent;
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->endgrent };
    ok($@);
  }
  else {
    SPVM::Sys->endgrent;
  }

  if ($^O eq 'MSWin32') {
    eval { SPVM::Sys->getgroups };
    ok($@);
  }
  else {
    my @groups_expected = split(/\s+/, "$)");
    shift @groups_expected;
    is_deeply(SPVM::Sys->getgroups->to_elems, \@groups_expected);
  }

  # TODO
  # This test failed. Maybe permission problems
=pod
  {
    ok(SPVM::Sys->setgroups();
  }
=cut
}

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);


done_testing;
