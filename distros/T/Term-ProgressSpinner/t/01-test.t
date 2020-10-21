use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;

my $line = 1;

# clear the screen and locate to line 1;
my @SPINNERS = sort grep { $_ ne 'default' }  keys %Term::ProgressSpinner::SPINNERS;

my @PROGRESS = sort grep { $_ ne 'default' } keys %Term::ProgressSpinner::PROGRESS;

my $ps = Term::ProgressSpinner->new(
	text_color => 'black on_bright_black',
	terminal_height => 40,
	precision => 2,
);

$ps->output->print("\e[${line};1f\e[2J");

$ps->sleep(1);
$ps->slowed(0.1);
$line++;
for (my $i = 0; $i < scalar @SPINNERS; $i++) {
	my $spin = $SPINNERS[$i];
	my $prog = $PROGRESS[$i];
	last unless $prog;
	$line++;
	print "PROGRESS: $prog - SPINNER: $spin \n";
	$ps->clear;
	$ps->terminal_line($line++);
	$ps->spinner($spin);
	$ps->progress($prog);
	$ps->start(20);
	while ($ps->advance) {}
	$ps->sleep(0.05);
}

$ps->output->print("\e[2J\e[1;1f");

ok(1);

done_testing();
