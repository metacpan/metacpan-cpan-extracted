package P5U::Command::Testers;

use 5.010;
use strict;
use utf8;
use P5U-command;

use PerlX::Maybe 0 'maybe';

BEGIN {
	$P5U::Command::Testers::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Testers::VERSION   = '0.100';
};

use constant {
	abstract    => q[show CPAN testers statistics for a distribution],
	usage_desc  => q[%c testers %o Distribution],
};

sub command_names
{
	qw(
		testers
		cpan-testers
		ct
	);
}

sub opt_spec
{
	return (
		["version|v=s",  "a specific version to query"],
		["summary|s",    "show summary for all versions"],
		["os|o",         "break down statistics by operating system"],
		["stable|z",     "ignore development versions"],
	)
}

sub execute
{
	require P5U::Lib::Testers;
	
	my ($self, $opt, $args) = @_;

	$self->usage_error("You must provide a distribution name.")
		if $opt->{summary} && ($opt->{os_data} or length $opt->{version});
		
	$self->usage_error("You must provide a distribution name.")
		if $opt->{stable} && length $opt->{version};
	
	my $distro = shift @$args
		or $self->usage_error("You must provide a distribution name.");
	$distro =~ s{::}{-}g;
	
	# no Test::Tabs
	my $helper = P5U::Lib::Testers::->new(
		      distro    =>   $distro,
		      os_data   => !!$opt->{os_data},
		      stable    => !!$opt->{stable},
		maybe version   =>   $opt->{version},
		      cache_dir =>   $self->get_cachedir,
	);
	# use Test::Tabs
	
	if ($opt->{summary})
		{ print $helper->summary_report }
	else
		{ print $helper->version_report }
}

1;
