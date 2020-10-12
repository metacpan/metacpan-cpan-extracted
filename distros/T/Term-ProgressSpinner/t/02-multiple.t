use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;
diag explain "TODO change to use a single progress spinner object.";
my $ps = Term::ProgressSpinner->new();
$ps->slowed(0.1);
$ps->start(20);
my $ps2 = Term::ProgressSpinner->new();
$ps2->slowed(0.1);
$ps2->start(10);

while (!$ps->finished || !$ps2->finished) {
	$ps->advance() unless $ps->finished;
	$ps2->advance() unless $ps2->finished;
}

ok(1);
done_testing();
