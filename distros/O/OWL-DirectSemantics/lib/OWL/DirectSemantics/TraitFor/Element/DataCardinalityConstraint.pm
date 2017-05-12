package OWL::DirectSemantics::TraitFor::Element::DataCardinalityConstraint;

BEGIN {
	$OWL::DirectSemantics::TraitFor::Element::DataCardinalityConstraint::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::TraitFor::Element::DataCardinalityConstraint::VERSION   = '0.001';
};

use 5.008;





use Moose::Role;

with 'OWL::DirectSemantics::TraitFor::Element::CardinalityConstraint';

has 'datarange'=> (is => 'rw', isa => 'RDF::Trine::Node', required=>0);

sub fs_arguments
{
	my ($self) = @_;
	return ($self->value, $self->property, $self->datarange) if defined $self->datarange;
	return ($self->value, $self->property);
}

1;
