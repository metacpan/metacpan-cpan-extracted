# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *

package RDFStore::Vocabulary::OWL;
{
use vars qw ( $VERSION $Ontology $Class $Thing $Nothing $equivalentClass $disjointWith $equivalentProperty $sameAs $differentFrom $AllDifferent $distinctMembers $unionOf $intersectionOf $complementOf $oneOf $Restriction $onProperty $allValuesFrom $hasValue $someValuesFrom $minCardinality $maxCardinality $cardinality $ObjectProperty $DatatypeProperty $inverseOf $TransitiveProperty $SymmetricProperty $FunctionalProperty $InverseFunctionalProperty $AnnotationProperty $OntologyProperty $imports $versionInfo $priorVersion $backwardCompatibleWith $incompatibleWith $DeprecatedClass $DeprecatedProperty $DataRange );
$VERSION='0.41';
use strict;
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Vocabulary::Generator
#

# Namespace URI of this schema
$RDFStore::Vocabulary::OWL::_Namespace= "http://www.w3.org/2002/07/owl#";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::OWL::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	$RDFStore::Vocabulary::OWL::Ontology = createResource($_[0], "Ontology");
	$RDFStore::Vocabulary::OWL::Class = createResource($_[0], "Class");
	$RDFStore::Vocabulary::OWL::Thing = createResource($_[0], "Thing");
	$RDFStore::Vocabulary::OWL::Nothing = createResource($_[0], "Nothing");
	$RDFStore::Vocabulary::OWL::equivalentClass = createResource($_[0], "equivalentClass");
	$RDFStore::Vocabulary::OWL::disjointWith = createResource($_[0], "disjointWith");
	$RDFStore::Vocabulary::OWL::equivalentProperty = createResource($_[0], "equivalentProperty");
	$RDFStore::Vocabulary::OWL::sameAs = createResource($_[0], "sameAs");
	$RDFStore::Vocabulary::OWL::differentFrom = createResource($_[0], "differentFrom");
	$RDFStore::Vocabulary::OWL::AllDifferent = createResource($_[0], "AllDifferent");
	$RDFStore::Vocabulary::OWL::distinctMembers = createResource($_[0], "distinctMembers");
	$RDFStore::Vocabulary::OWL::unionOf = createResource($_[0], "unionOf");
	$RDFStore::Vocabulary::OWL::intersectionOf = createResource($_[0], "intersectionOf");
	$RDFStore::Vocabulary::OWL::complementOf = createResource($_[0], "complementOf");
	$RDFStore::Vocabulary::OWL::oneOf = createResource($_[0], "oneOf");
	$RDFStore::Vocabulary::OWL::Restriction = createResource($_[0], "Restriction");
	$RDFStore::Vocabulary::OWL::onProperty = createResource($_[0], "onProperty");
	$RDFStore::Vocabulary::OWL::allValuesFrom = createResource($_[0], "allValuesFrom");
	$RDFStore::Vocabulary::OWL::hasValue = createResource($_[0], "hasValue");
	$RDFStore::Vocabulary::OWL::someValuesFrom = createResource($_[0], "someValuesFrom");
	$RDFStore::Vocabulary::OWL::minCardinality = createResource($_[0], "minCardinality");
	$RDFStore::Vocabulary::OWL::maxCardinality = createResource($_[0], "maxCardinality");
	$RDFStore::Vocabulary::OWL::cardinality = createResource($_[0], "cardinality");
	$RDFStore::Vocabulary::OWL::ObjectProperty = createResource($_[0], "ObjectProperty");
	$RDFStore::Vocabulary::OWL::DatatypeProperty = createResource($_[0], "DatatypeProperty");
	$RDFStore::Vocabulary::OWL::inverseOf = createResource($_[0], "inverseOf");
	$RDFStore::Vocabulary::OWL::TransitiveProperty = createResource($_[0], "TransitiveProperty");
	$RDFStore::Vocabulary::OWL::SymmetricProperty = createResource($_[0], "SymmetricProperty");
	$RDFStore::Vocabulary::OWL::FunctionalProperty = createResource($_[0], "FunctionalProperty");
	$RDFStore::Vocabulary::OWL::InverseFunctionalProperty = createResource($_[0], "InverseFunctionalProperty");
	$RDFStore::Vocabulary::OWL::AnnotationProperty = createResource($_[0], "AnnotationProperty");
	$RDFStore::Vocabulary::OWL::OntologyProperty = createResource($_[0], "OntologyProperty");
	$RDFStore::Vocabulary::OWL::imports = createResource($_[0], "imports");
	$RDFStore::Vocabulary::OWL::versionInfo = createResource($_[0], "versionInfo");
	$RDFStore::Vocabulary::OWL::priorVersion = createResource($_[0], "priorVersion");
	$RDFStore::Vocabulary::OWL::backwardCompatibleWith = createResource($_[0], "backwardCompatibleWith");
	$RDFStore::Vocabulary::OWL::incompatibleWith = createResource($_[0], "incompatibleWith");
	$RDFStore::Vocabulary::OWL::DeprecatedClass = createResource($_[0], "DeprecatedClass");
	$RDFStore::Vocabulary::OWL::DeprecatedProperty = createResource($_[0], "DeprecatedProperty");
	$RDFStore::Vocabulary::OWL::DataRange = createResource($_[0], "DataRange");
};
sub END {
	$RDFStore::Vocabulary::OWL::Ontology = undef;
	$RDFStore::Vocabulary::OWL::Class = undef;
	$RDFStore::Vocabulary::OWL::Thing = undef;
	$RDFStore::Vocabulary::OWL::Nothing = undef;
	$RDFStore::Vocabulary::OWL::equivalentClass = undef;
	$RDFStore::Vocabulary::OWL::disjointWith = undef;
	$RDFStore::Vocabulary::OWL::equivalentProperty = undef;
	$RDFStore::Vocabulary::OWL::sameAs = undef;
	$RDFStore::Vocabulary::OWL::differentFrom = undef;
	$RDFStore::Vocabulary::OWL::AllDifferent = undef;
	$RDFStore::Vocabulary::OWL::distinctMembers = undef;
	$RDFStore::Vocabulary::OWL::unionOf = undef;
	$RDFStore::Vocabulary::OWL::intersectionOf = undef;
	$RDFStore::Vocabulary::OWL::complementOf = undef;
	$RDFStore::Vocabulary::OWL::oneOf = undef;
	$RDFStore::Vocabulary::OWL::Restriction = undef;
	$RDFStore::Vocabulary::OWL::onProperty = undef;
	$RDFStore::Vocabulary::OWL::allValuesFrom = undef;
	$RDFStore::Vocabulary::OWL::hasValue = undef;
	$RDFStore::Vocabulary::OWL::someValuesFrom = undef;
	$RDFStore::Vocabulary::OWL::minCardinality = undef;
	$RDFStore::Vocabulary::OWL::maxCardinality = undef;
	$RDFStore::Vocabulary::OWL::cardinality = undef;
	$RDFStore::Vocabulary::OWL::ObjectProperty = undef;
	$RDFStore::Vocabulary::OWL::DatatypeProperty = undef;
	$RDFStore::Vocabulary::OWL::inverseOf = undef;
	$RDFStore::Vocabulary::OWL::TransitiveProperty = undef;
	$RDFStore::Vocabulary::OWL::SymmetricProperty = undef;
	$RDFStore::Vocabulary::OWL::FunctionalProperty = undef;
	$RDFStore::Vocabulary::OWL::InverseFunctionalProperty = undef;
	$RDFStore::Vocabulary::OWL::AnnotationProperty = undef;
	$RDFStore::Vocabulary::OWL::OntologyProperty = undef;
	$RDFStore::Vocabulary::OWL::imports = undef;
	$RDFStore::Vocabulary::OWL::versionInfo = undef;
	$RDFStore::Vocabulary::OWL::priorVersion = undef;
	$RDFStore::Vocabulary::OWL::backwardCompatibleWith = undef;
	$RDFStore::Vocabulary::OWL::incompatibleWith = undef;
	$RDFStore::Vocabulary::OWL::DeprecatedClass = undef;
	$RDFStore::Vocabulary::OWL::DeprecatedProperty = undef;
	$RDFStore::Vocabulary::OWL::DataRange = undef;
};
1;
};
