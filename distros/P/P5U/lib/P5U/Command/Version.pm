package P5U::Command::Version;

use 5.010;
use strict;
use utf8;
use P5U-command;

use PerlX::Maybe 0 'maybe';

BEGIN {
	$P5U::Command::Version::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Version::VERSION   = '0.100';
};

use constant {
	abstract    => q[show the version number of a module],
	usage_desc  => q[%c version %o Module],
};

sub command_names
{
	qw(
		version
		v
	);
}

sub description
{
<<'DESCRIPTION'
This command is inspired by V.pm. Given one or more module names, it
locates the modules on your local system and tells you the version
number. (Note that you may have multiple versions of a module installed
in different locations.)

	p5u v MooseX::Types MouseX::Types

Unlike V.pm, it also has the ability to reach out to CPAN/BackPAN and find
versions of the module available there:

	p5u v -c MooseX::Types
	p5u v -b MooseX::Types

You can even combine options:

	p5u v -lcb MooseX::Types
	p5u v -lc MooseX::Types MouseX::Types

If no options are provided, defaults to "--local".
DESCRIPTION
}

sub opt_spec
{
	return (
		['cpan|c'     => 'search CPAN'],
		['local|l'    => 'search @INC'],
		['backpan|b'  => 'search BackPAN'],
	);
}

sub execute
{
	my ($self, $opt, $args) = @_;

	$opt->{local}++ unless $opt->{cpan} || $opt->{backpan};
	$self->usage_error("You must provide a module name.")
		unless @$args;
	
	require P5U::Lib::Version;
	my $helper = 'P5U::Lib::Version';
		
	while (my $m = shift @$args)
	{
		say $m;
		
		my @lines;
		push @lines, $helper->local_module_info($m)   if $opt->{local};
		push @lines, $helper->cpan_module_info($m)    if $opt->{cpan};
		push @lines, $helper->backpan_module_info($m) if $opt->{backpan};
		push @lines, q(Not found) unless @lines;
		
		say "\t$_" for @lines;
		say q() if @$args;
	}
}

1;
