package RDF::Closure::Rule::Programmatic;

use 5.008;
use strict;
use utf8;

use Error qw[:try];
use RDF::Trine;

use base qw[RDF::Closure::Rule::Core];

our $VERSION = '0.001';

sub new
{
	my ($class, $code, $name) = @_;
	
	throw Error::Simple("Code must be a coderef.")
		unless ref $code eq 'CODE';
	
	bless { code => $code, name => $name }, $class;
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
	$self->call($closure, $self);
	$self->post_atc;
}

1;

