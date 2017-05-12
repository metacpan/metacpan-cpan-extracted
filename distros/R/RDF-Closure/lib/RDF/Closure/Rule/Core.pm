package RDF::Closure::Rule::Core;

use 5.008;
use strict;
use utf8;

use Error qw[:try];
use RDF::Trine;
use Time::HiRes qw[time];

our $VERSION = '0.001';

sub name
{
	my ($self) = @_;
	return $self->{name};
}

sub debug
{
	my ($self, $message) = @_;
	printf("+ %s%s\n", $self->name, (defined $message ? ": $message" : ''))
		if $RDF::Closure::Engine::Core::debugGlobal;
}

sub apply_to_closure
{
	my ($self, $closure) = @_;
	throw Error "This method should not be called directly; subclasses should override it.";
}

sub pre_atc
{
	my ($self) = @_;
	$self->debug('BEGIN');
	$self->{start_time} = time();
}

sub post_atc
{
	my ($self) = @_;
	$self->debug(sprintf("END %03.03f seconds", (time() - $self->{start_time})));
	delete $self->{start_time};
}

1;

