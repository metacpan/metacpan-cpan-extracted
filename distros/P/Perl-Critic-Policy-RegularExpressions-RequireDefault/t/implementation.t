use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::RegularExpressions::RequireDefault');

ok(my $policy = Perl::Critic::Policy::RegularExpressions::RequireDefault->new());

isa_ok($policy, 'Perl::Critic::Policy::RegularExpressions::RequireDefault');

can_ok($policy, qw(violates));
