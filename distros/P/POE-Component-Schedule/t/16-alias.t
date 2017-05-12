use strict;
use warnings;

use Test::More tests => 5;
sub POE::Component::Schedule::DEBUG { 1 }
use POE 'Component::Schedule';

my $alias = 'Scheduler';
my $ses = POE::Component::Schedule->spawn(Alias => $alias);

is(POE::Kernel->alias_list($ses), $alias, "Alias check");

POE::Kernel->run;

$ses = POE::Component::Schedule->spawn;
isnt(POE::Kernel->alias_list($ses), $alias, "Alias check");

POE::Kernel->run;

pass;

$ses = POE::Component::Schedule->spawn(Alias => $alias);
is(POE::Kernel->alias_list($ses), $alias, "Alias check");

POE::Kernel->run;

pass;

