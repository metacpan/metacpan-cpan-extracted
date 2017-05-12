package P5U::Command::TestPod;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::TestPod::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::TestPod::VERSION   = '0.100';
};

use constant {
	abstract    => q[run Test::Pod on given files],
	usage_desc  => q[%c testpod %o Files],
};

sub command_names
{
	qw(
		testpod
		tp
	);
}

sub opt_spec
{
	return ()
}

sub execute
{
	require P5U::Lib::TestPod;
	
	my ($self, $opt, $args) = @_;

	if (not @$args)
	{
		-d 'lib' or $self->usage_error("please provide a list of files/directories");
		$args = ['lib'];
	}
	
	P5U::Lib::TestPod::->test_pod(@$args);
}

1;
