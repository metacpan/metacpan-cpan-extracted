use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Sim::Clock'); }

my $clock = Sim::Clock->new;
ok $clock, 'obj ok';
isa_ok $clock, 'Sim::Clock';
is $clock->now, 0, 'now defaults to 0';

ok $clock->push_to(3), 'push to 3 ok';
is $clock->now, 3, 'now is 3';

warn "You can safely ignore the following error message (if any):\n";
ok !$clock->push_to(2), "can't push back";

ok $clock->push_to(3), 'we can push to *now*';
is $clock->now, 3, 'now is still 3';

$clock->reset;
is $clock->now, 0, 'reset works';

$clock = Sim::Clock->new(31);
is $clock->now, 31, 'new/1 works';

