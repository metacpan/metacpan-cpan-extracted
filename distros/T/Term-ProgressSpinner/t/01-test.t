use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;

my @SPINNERS = sort grep { $_ ne 'default' }  keys %Term::ProgressSpinner::SPINNERS;

my @PROGRESS = sort grep { $_ ne 'default' } keys %Term::ProgressSpinner::PROGRESS;

my $ps = Term::ProgressSpinner->new();
$ps->sleep(0.4);
$ps->slowed(0.1);
for (my $i = 0; $i < scalar @SPINNERS; $i++) {
	my $spin = $SPINNERS[$i];
	my $prog = $PROGRESS[$i];
	last unless $prog;
	print "PROGRESS: $prog - SPINNER: $spin \n";
	$ps->clear;
	$ps->spinner($spin);
	$ps->progress($prog);
	$ps->start(20);
	while ($ps->advance) {}
	$ps->sleep(0.05);
}

ok(1);

done_testing();
