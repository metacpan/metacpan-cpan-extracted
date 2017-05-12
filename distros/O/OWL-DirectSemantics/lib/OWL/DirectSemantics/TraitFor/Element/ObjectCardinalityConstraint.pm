package OWL::DirectSemantics::TraitFor::Element::ObjectCardinalityConstraint;

BEGIN {
	$OWL::DirectSemantics::TraitFor::Element::ObjectCardinalityConstraint::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::TraitFor::Element::ObjectCardinalityConstraint::VERSION   = '0.001';
};

use 5.008;





use Moose::Role;

with 'OWL::DirectSemantics::TraitFor::Element::CardinalityConstraint';

has 'class'    => (is => 'rw', isa => 'RDF::Trine::Node', required=>0);

sub fs_arguments
{
	my ($self) = @_;
	return ($self->value, $self->property, $self->class) if defined $self->class;
	return ($self->value, $self->property);
}


1;
