package _driver;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(runtest);

use ProgressMonitor::Stringify::ToCallback;
use ProgressMonitor::SubTask;

use Test::More;

sub runtest
{
	my $field        = shift;
	my $prepareTicks = shift;
	my $activeTicks1 = shift;
	my $subtaskTicks = shift;
	my $activeTicks2 = shift;
	my $renderings   = shift;

	# plan for the requested loops, don't forget 3 extra renderings (prepare, begin, end)
	#
	#	plan tests => $prepareTicks + $activeTicks1 + ($subtaskTicks->[0] ? $subtaskTicks->[] + $activeTicks2 + 3;
	plan tests => scalar(@$renderings);

	my $index = 0;
	my $cb = sub {
		my $rendering = shift;
		my $atIndex   = $index++;
		my $expected  = $renderings->[$atIndex];
		if ($rendering eq $expected)
		{
			ok(1);
		}
		else
		{
			print STDERR "\nSAW: '$rendering', EXPECTED: '$expected', AT: '$atIndex'\n";
			ok(0);
		}
		return 0;
	};

	my $monitor = ProgressMonitor::Stringify::ToCallback->new({maxWidth => 79, fields => [$field], tickCallback => $cb});
	$monitor->prepare;
	$monitor->tick for (1 .. $prepareTicks);
	$monitor->begin($activeTicks1 + $subtaskTicks->[0] + $activeTicks2);
	$monitor->tick(1) for (1 .. $activeTicks1);
	runSubTask(ProgressMonitor::SubTask->new({parent => $monitor, parentTicks => $subtaskTicks->[0]}),
			   $subtaskTicks->[1], $subtaskTicks->[2])
	  if $subtaskTicks->[0];
	$monitor->tick(1) for (1 .. $activeTicks2);
	$monitor->end;
}

sub runSubTask
{
	my $monitor      = shift;
	my $prepareTicks = shift;
	my $activeTicks  = shift;

	$monitor->prepare;
	$monitor->tick for (1 .. $prepareTicks);
	$monitor->begin($activeTicks);
	$monitor->tick(1) for (1 .. $activeTicks);
	$monitor->end;
}

1;
