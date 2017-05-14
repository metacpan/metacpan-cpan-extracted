use strict;
use warnings;

use Test::More;

use ProgressMonitor::Stringify::ToCallback;
use ProgressMonitor::Stringify::Fields::Fixed;

my $msg = 'xyz';

my @renderings = (
				  "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick",
				  "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick",
				  "tick", "xyz.", "tick", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick",
				  "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick", "xyz.", "tick",
				  "tick", "xyz.", "tick", "tick", "xyz.", "tick", "tick",
				 );
plan tests => scalar(@renderings);

my $index = 0;
my $cb = sub {
	my $rendering = shift;
	my $expected  = $renderings[$index++];
	if ($rendering eq $expected)
	{
		ok(1);
	}
	else
	{
		print STDERR "\nSAW: '$rendering', EXPECTED: '$expected'\n";
		ok(0);
	}
	return 0;
};

my $monitor =
  ProgressMonitor::Stringify::ToCallback->new(
											  {
											   maxWidth      => 79,
											   fields        => [ProgressMonitor::Stringify::Fields::Fixed->new({text => "tick"})],
											   tickCallback  => $cb,
											   messageFiller => '.',
											   messageStrategy => 'overlay'
											  }
											 );
$monitor->prepare;
for (1 .. 10)
{
	$monitor->tick;
	$monitor->setMessage($msg);
	$monitor->setMessage(undef);
}
$monitor->begin(10);
for (1 .. 10)
{
	$monitor->tick(1);
	$monitor->setMessage($msg);
	$monitor->setMessage(undef);
}
$monitor->end;
