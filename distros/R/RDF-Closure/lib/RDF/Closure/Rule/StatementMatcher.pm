package RDF::Closure::Rule::StatementMatcher;

use 5.008;
use strict;
use utf8;

use Error qw[:try];
use RDF::Trine;

use base qw[RDF::Closure::Rule::Core];

our $VERSION = '0.001';

sub new
{
	my ($class, $pattern, $code, $name) = @_;
	
	throw Error "Pattern must be an arrayref."
		unless ref $pattern eq 'ARRAY';
	throw Error "Code must be a coderef."
		unless ref $code eq 'CODE';
	
	bless { pattern => $pattern, code => $code, name => $name }, $class;
}

sub pattern
{
	$_[0]->{pattern};
}

sub matches_statement
{
	my ($self, $st) = @_;
	
	my $pattern = $self->pattern;
	
	return
		if (defined $pattern->[1] and !$pattern->[1]->equal($st->predicate));

	return
		if (defined $pattern->[2] and !$pattern->[2]->equal($st->object));

	return
		if (defined $pattern->[0] and !$pattern->[0]->equal($st->subject));

	return 1;
}

sub call
{
	my $self = shift;
	$self->{code}->(@_);
}

sub apply_to_closure
{
	my ($self, $closure) = @_;
	$self->pre_atc;
	
	$closure->graph->get_statements(@{$self->pattern})->each(sub {
		my ($st) = @_;
		$self->call($closure, $st, $self);
	});
	
	$self->post_atc;
}

sub apply_to_closure_given_statement
{
	my ($self, $closure, $st) = @_;
	$self->debug;
	$self->call($closure, $st, $self)
		if $self->matches_statement($st);
	$self;
}

1;

