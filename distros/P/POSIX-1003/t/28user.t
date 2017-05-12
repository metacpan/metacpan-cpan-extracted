#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::User qw/getuid setuid getgroups/;

my $uid = getuid();
defined $uid or plan skip_all => 'getuid not available';

plan tests => 3;
ok(defined $uid, "getuid=$uid");

SKIP: {
   skip 'tests for non-root', 1 if $uid==0;

   $uid++;
   ok(!defined setuid $uid, "setuid $uid, $!");
}

my $groups = join ', ', getgroups;
ok(defined $groups, "groups: $groups");
