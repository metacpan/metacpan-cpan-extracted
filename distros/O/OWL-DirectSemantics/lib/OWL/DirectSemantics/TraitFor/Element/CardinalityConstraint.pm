package OWL::DirectSemantics::TraitFor::Element::CardinalityConstraint;

BEGIN {
	$OWL::DirectSemantics::TraitFor::Element::CardinalityConstraint::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::TraitFor::Element::CardinalityConstraint::VERSION   = '0.001';
};

use 5.008;





use Moose::Role;

has 'property' => (is => 'rw', isa => 'RDF::Trine::Node', required=>1);
has 'value'    => (is => 'rw', isa => 'RDF::Trine::Node', required=>1);

1;
