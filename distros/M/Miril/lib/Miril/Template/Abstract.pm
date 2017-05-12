package Miril::Template::Abstract;

use strict;
use warnings;
use autodie;

sub new {
	my $class = shift;
	my $miril = shift;
	my $tmpl_path = $miril->cfg->tmpl_path;

	my $self = bless {}, $class;

	$self->{miril} = $miril;

	$self->{tmpl_path} = $tmpl_path;

	return $self;
}

sub tmpl_path {shift->{tmpl_path}}
sub miril     {shift->{miril}}

1;
