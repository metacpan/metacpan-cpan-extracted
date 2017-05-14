use strict;
use warnings;

use Test::More;

use ProgressMonitor::Stringify::ToCallback;
use ProgressMonitor::Stringify::Fields::Fixed;

my $msg = 'xyz';

plan tests => 83 * 3;

# this particular test shows that the strategy is not relevant
#
runtest('overlay');
runtest('newline');
runtest('none');

sub runtest
{
	my $strategy = shift;

	my $cb = sub {
		my $rendering = shift;
		my $expected  = 'tick';
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

	my $mb = sub {
		my $rendering = shift;
		my $expected  = $msg;
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
												   maxWidth => 79,
												   fields   => [ProgressMonitor::Stringify::Fields::Fixed->new({text => "tick"})],
												   tickCallback    => $cb,
												   messageCallback => $mb,
												   messageFiller   => '.',
												   messageStrategy => $strategy
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
}
