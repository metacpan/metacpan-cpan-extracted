use strict;
use warnings;

# this test resembles one that would be generated with Dist::Zilla::Plugin::Test::CheckBreaks 0.011

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Module::Runtime::Conflicts;

eval { Module::Runtime::Conflicts->check_conflicts };

diag $@ if $@;
pass 'conflicts checked via Module::Runtime::Conflicts';

done_testing;
