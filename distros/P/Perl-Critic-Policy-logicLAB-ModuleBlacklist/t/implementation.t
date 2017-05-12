
# $Id: implementation.t 7587 2011-04-16 16:00:36Z jonasbn $

use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::logicLAB::ModuleBlacklist');

ok(my $policy = Perl::Critic::Policy::logicLAB::ModuleBlacklist->new());

isa_ok($policy, 'Perl::Critic::Policy::logicLAB::ModuleBlacklist');

can_ok($policy, qw(violates));
