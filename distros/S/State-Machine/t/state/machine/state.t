use strict;
use warnings;

use Test::More;
use State::Machine::State;

my $class = 'State::Machine::State';
can_ok $class => qw(name next transitions);

my $state1 = eval { $class->new };
ok !$state1 && $@, '$state1 missing required arguments';

my $state2 = $class->new(name => 'performed');
is $state2->name, 'performed', '$state2 instantiated';

is_deeply $state2->transitions, {}, '$state2 has no transitions';

ok 1 and done_testing;
