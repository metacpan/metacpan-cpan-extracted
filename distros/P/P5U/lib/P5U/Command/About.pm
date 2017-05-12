package P5U::Command::About;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::About::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::About::VERSION   = '0.100';
};

use constant {
	abstract    => q[list which P5U plugins are installed],
	usage_desc  => q[%c about],
};

use constant FORMAT_STR => "%-30s%10s %s\n";

sub command_names
{
	qw(
		about
		credits
	);
}

sub opt_spec
{
	return;
}

sub execute
{
	my ($self, $opt, $args) = @_;
	
	my $auth = $self->app->can('AUTHORITY');
	printf(
		FORMAT_STR,
		ref($self->app),
		$self->app->VERSION,
		$auth ? $self->app->$auth : '???',
	);
	
	foreach my $cmd (sort $self->app->command_plugins)
	{
		my $auth = $cmd->can('AUTHORITY');
		printf(
			FORMAT_STR,
			$cmd,
			$cmd->VERSION,
			$auth ? $cmd->$auth : '???',
		);
	}
}

1;
