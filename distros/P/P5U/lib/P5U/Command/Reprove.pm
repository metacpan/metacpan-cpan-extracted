package P5U::Command::Reprove;

use 5.010;
use strict;
use utf8;
use P5U-command;

use PerlX::Maybe 0 'maybe';

BEGIN {
	$P5U::Command::Reprove::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Reprove::VERSION   = '0.100';
};

use constant {
	abstract    => q[download a distribution test suite and run it],
	usage_desc  => q[%c reprove %o],
};

sub command_names
{
	qw(
		reprove
		rp
	);
}

sub description
{
<<'DESCRIPTION'
This command downloads a distribution's test suite from CPAN, and runs it
locally.

This command can be called using two different conventions; named arguments:

	p5u reprove --release=JSON --version=2.53

Or positional arguments:

	p5u reprove JSON 2.53

The first argument is the distribution name or module name; the second
argument is the version; and the third argument is the CPAN ID of the
author. The presence of "::" is used to disambiguate between distribution
and module names; in the case of something like "JSON" which is ambiguous,
use a trailing "::" to force it to be interpreted as a module name.

When given a distribution name, the version is required. When given a
module name, the version can usually be automatically detected. The author
can usually be automatically detected.
DESCRIPTION
}

sub opt_spec
{
	return (
		["author|a=s",   "author of distribution to test"],
		["version=s",    "version to test"],
		["module|m=s",   "identify distribution via a module it provides"],
		["release|r=s",  "name of distribution to test"],
		["verbose|v",    "verbose output"],
	)
}

sub execute
{
	require P5U::Lib::Reprove;
	
	my ($self, $opt, $args) = @_;

	foreach my $a (qw< release version author >)
	{
		my $val = shift @$args;
		defined $val or last;
		$self->usage_error("Do not provide $a as a named and ordinal argument.")
			if defined $opt->{$a};
		
		if ($a eq 'release' and $val =~ /::/)
		{
			$val =~ s{::$}{};
			$opt->{module} = $val;
			next;
		}
		
		$opt->{$a} = $val;
	}
	
	$self->usage_error("You must provide a distribution or module name.")
		unless $opt->{release} || $opt->{module};
	
	P5U::Lib::Reprove::
		-> new(
			maybe author      => $opt->{author},
			maybe module      => $opt->{module},
			maybe release     => $opt->{release},
			maybe version     => $opt->{version},
			maybe verbose     => $opt->{verbose},
			      working_dir => $self->get_tempdir, ##WS
		)
		-> run;
}

1;
