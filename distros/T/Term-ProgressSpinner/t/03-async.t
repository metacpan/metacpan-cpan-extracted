use Test::More;
use strict;
use warnings;
use Term::ProgressSpinner;

eval { require IO::Async::Loop };
if ($@) {
	plan skip_all => 'IO::Async::Loop not available';
}

my $line = 1;

my $ps = Term::ProgressSpinner->new(
	terminal_height => 43,
	message => '{spinner} Async spinner test...',
);

$ps->output->print("\e[${line};1f\e[2J");

my $loop = IO::Async::Loop->new;

$ps->terminal_line($line++);
$ps->start_async($loop, interval => 0.05);

# Run the loop for a bit to see animation
for (1 .. 20) {
	$loop->loop_once(0.05);
}

$ps->stop_async("Async complete!");

$ps->sleep(0.5);

# Test with different spinner
$ps = Term::ProgressSpinner->new(
	terminal_height => 43,
	spinner => 'moon',
	message => '{spinner} Moon spinner async...',
);

$ps->terminal_line($line++);
$ps->start_async($loop, interval => 0.1);

for (1 .. 15) {
	$loop->loop_once(0.1);
}

$ps->stop_async("Moon done!");

$ps->output->print("\e[2J\e[1;1f");

ok(1);

done_testing();
