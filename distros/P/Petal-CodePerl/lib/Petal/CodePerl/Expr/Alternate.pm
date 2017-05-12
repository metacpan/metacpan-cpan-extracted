use strict;
use warnings;

package Petal::CodePerl::Expr::Alternate;

use base qw( Code::Perl::Expr::Base );

use Class::MethodMaker (
	get_set => [qw( -java Paths )]
);

sub eval
{
	my $self = shift;

	my @paths = @{$self->getPaths};

	my $last = pop @paths;

	foreach my $path (@paths)
	{
		my $res = eval {$path->eval};
		next if $@;
		return $res;
	}

	return $last->eval;
}

sub perl
{
	my $self = shift;

	my @paths = @{$self->getPaths};

	my $last = pop @paths;

	my $last_perl = $last->perl;
	if (not @paths)
	{
		return $last_perl;
	}
	else
	{
		my @evals = map {
			my $path_perl = $_->perl;
			qq{eval{\$v = $path_perl}; last unless \$@}
		} @paths;
		my $evals = join(";", @evals);

		return qq{do{my \$v;for (1){$evals;\$v = $last_perl} \$v}}
	}
}

1;
