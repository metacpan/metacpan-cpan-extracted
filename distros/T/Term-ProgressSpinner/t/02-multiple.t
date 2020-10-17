use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;

my $line = 1;

my $ps = Term::ProgressSpinner->new(
	terminal_height => 43
);

$ps->output->print("\e[${line};1f\e[2J");

$ps->slowed(0.1);

$ps->terminal_line($line++);
my $s1 = $ps->start(20);
$ps->terminal_line($line++);
my $s2 = $ps->start(10);
$ps->terminal_line($line++);
my $s3 = $ps->start(50);
$ps->terminal_line($line++);
my $s4 = $ps->start(30);
 
while (!$ps->finished) {
        $ps->advance($s1) unless $s1->finished;
        $ps->advance($s2) unless $s2->finished;
        $ps->advance($s3) unless $s3->finished;
        $ps->advance($s4) unless $s4->finished;
}
 
$ps->terminal_line($line++);
$s1 = $ps->start(20);
$ps->terminal_line($line++);
$s2 = $ps->start(10);
$ps->terminal_line($line++);
$s3 = $ps->start(50);
$ps->terminal_line($line++);
$s4 = $ps->start(30);
 
while ($ps->advance()) {}
 
 
 
ok(1);
done_testing();
