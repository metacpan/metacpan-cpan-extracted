use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;
diag explain "TODO change to use a single progress spinner object.";
my $ps = Term::ProgressSpinner->new();
$ps->slowed(0.1);
my $s1 = $ps->start(20);
my $s2 = $ps->start(10);
my $s3 = $ps->start(50);
my $s4 = $ps->start(30);
 
while (!$ps->finished) {
        $ps->advance($s1) unless $s1->finished;
        $ps->advance($s2) unless $s2->finished;
        $ps->advance($s3) unless $s3->finished;
        $ps->advance($s4) unless $s4->finished;
}
 
$s1 = $ps->start(20);
$s2 = $ps->start(10);
$s3 = $ps->start(50);
$s4 = $ps->start(30);
 
while ($ps->advance()) {}
 
 
 
ok(1);
done_testing();
