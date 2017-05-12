package P5U::Command::Aliases;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::Aliases::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Aliases::VERSION   = '0.100';
};

use constant {
	abstract    => q[show aliases for p5u's commands],
	usage_desc  => q[%c aliases],
};

sub description
{
<<'DESCRIPTION'
Most p5u commands can be invoked with shorter aliases.

	p5u version Mouse
	p5u v Mouse           # same thing

The aliases command (which, ironically, has no shorter alias) shows existing
aliases.
DESCRIPTION
}

sub command_names
{
	qw(
		aliases
	);
}

sub opt_spec
{
	return;
}

sub execute
{
	my ($self, $opt, $args) = @_;
	
	require match::smart;
	my $filter = scalar(@$args)
		? $args
		: sub { !match::smart::match(shift, [qw(aliases commands help)]) };
	
	foreach my $cmd (sort $self->app->command_plugins)
	{
		my ($preferred, @aliases) = $cmd->command_names;
		printf("%-16s: %s\n", $preferred, "@aliases")
			if match::smart::match($preferred, $filter);
	}
}

1;
