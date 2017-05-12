
# $Id$

use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::logicLAB::RequireSheBang');

ok(my $policy = Perl::Critic::Policy::logicLAB::RequireSheBang->new());

isa_ok($policy, 'Perl::Critic::Policy::logicLAB::RequireSheBang');

can_ok($policy, qw(violates));
