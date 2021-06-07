use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling');

ok(my $policy = Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling->new());

isa_ok($policy, 'Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling');

can_ok($policy, qw(violates));
