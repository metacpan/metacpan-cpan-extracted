package P5U::Command::AutoProve;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::AutoProve::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::AutoProve::VERSION   = '0.100';
};

use Cwd 'cwd';

use constant {
	abstract    => q[automatically find the most likely test suite, and run it],
	usage_desc  => q[%c auto-prove %o],
};

sub command_names
{
	qw(
		auto-prove
		ap
	);
}

sub description
{
<<'DESCRIPTION'
The auto-prove command climbs up your directory hierarchy, looking for a
directory which has a subdirectory called "t". It then performs a chdir to
that directory, runs "prove" with the most likely options and does a chdir
back to where you started.

In short, if you're in a terminal working in some deeply nested directory
containing code files, you don't need to play the "guess how many
dot-dot-slashes game". Just type "p5u ap".

You can additionally run author tests using "p5u ap --xt".
DESCRIPTION
}

sub opt_spec
{
	require P5U::Lib::AutoProve;
	return (
		[ xt => 'run "xt" tests too' ],
		map { [ $_ => 'passed through to "prove"' ] } P5U::Lib::AutoProve->opts
	);
}

sub execute
{
	require P5U::Lib::AutoProve;
	my ($self, $opt, $args) = @_;
	$self->usage_error("This command takes no non-option arguments.")
		if @$args;
	my ($wd, $app) = P5U::Lib::AutoProve::->get_app(%$opt);
	my $orig = cwd;
	
	chdir $wd;
	$app->run;
	chdir $orig;
}

1;
