use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::logicLAB::ProhibitShellDispatch');

ok(my $policy = Perl::Critic::Policy::logicLAB::ProhibitShellDispatch->new());

isa_ok($policy, 'Perl::Critic::Policy::logicLAB::ProhibitShellDispatch');

can_ok($policy, qw(violates));
