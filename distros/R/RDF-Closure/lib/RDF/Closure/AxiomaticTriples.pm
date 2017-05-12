package RDF::Closure::AxiomaticTriples;

use 5.008;
use strict;
use utf8;

use RDF::Trine qw[statement];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];

use base qw[Exporter];

our $VERSION = '0.001';

our @EXPORT = qw[];
our @EXPORT_OK = qw[
	$RDFS_Axiomatic_Triples 
	$RDFS_D_Axiomatic_Triples_subclasses 
	$RDFS_D_Axiomatic_Triples_types 
	$RDFS_D_Axiomatic_Triples 
	$OWLRL_Axiomatic_Triples   
	$OWL_D_Axiomatic_Triples_subclasses 
	$OWLRL_Datatypes_Disjointness 
	$OWLRL_D_Axiomatic_Triples 
	];

#: Simple RDF axiomatic triples statement(typing of $RDF->subject, $RDF->predicate, $RDF->first, $RDF->rest, etc)
our $_Simple_RDF_axiomatic_triples = [
	statement($RDF->type, $RDF->type, $RDF->Property),
	statement($RDF->subject, $RDF->type, $RDF->Property),
	statement($RDF->predicate, $RDF->type, $RDF->Property),
	statement($RDF->object, $RDF->type, $RDF->Property),
	statement($RDF->first, $RDF->type, $RDF->Property),
	statement($RDF->rest, $RDF->type, $RDF->Property),
	statement($RDF->value, $RDF->type, $RDF->Property),
	statement($RDF->nil, $RDF->type, $RDF->List),
];

#: RDFS axiomatic triples statement($RDFS->domain and $RDFS->range, as well as class setting for a number of RDFS symbols)
our $_RDFS_axiomatic_triples = [
	statement($RDF->type, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->domain, $RDFS->domain, $RDF->Property),
	statement($RDFS->range, $RDFS->domain, $RDF->Property),
	statement($RDFS->subPropertyOf, $RDFS->domain, $RDF->Property),
	statement($RDFS->subClassOf, $RDFS->domain, $RDFS->Class),
	statement($RDF->subject, $RDFS->domain, $RDF->Statement),
	statement($RDF->predicate, $RDFS->domain, $RDF->Statement),
	statement($RDF->object, $RDFS->domain, $RDF->Statement),
	statement($RDFS->member, $RDFS->domain, $RDFS->Resource),
	statement($RDF->first, $RDFS->domain, $RDF->List),
	statement($RDF->rest, $RDFS->domain, $RDF->List),
	statement($RDFS->seeAlso, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->isDefinedBy, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->comment, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->label, $RDFS->domain, $RDFS->Resource),
	statement($RDF->value, $RDFS->domain, $RDFS->Resource),
	statement($RDF->Property, $RDF->type, $RDFS->Class),

	statement($RDF->type, $RDFS->range, $RDFS->Class),
	statement($RDFS->domain, $RDFS->range, $RDFS->Class),
	statement($RDFS->range, $RDFS->range, $RDFS->Class),
	statement($RDFS->subPropertyOf, $RDFS->range, $RDF->Property),
	statement($RDFS->subClassOf, $RDFS->range, $RDFS->Class),
	statement($RDF->subject, $RDFS->range, $RDFS->Resource),
	statement($RDF->predicate, $RDFS->range, $RDFS->Resource),
	statement($RDF->object, $RDFS->range, $RDFS->Resource),
	statement($RDFS->member, $RDFS->range, $RDFS->Resource),
	statement($RDF->first, $RDFS->range, $RDFS->Resource),
	statement($RDF->rest, $RDFS->range, $RDF->List),
	statement($RDFS->seeAlso, $RDFS->range, $RDFS->Resource),
	statement($RDFS->isDefinedBy, $RDFS->range, $RDFS->Resource),
	statement($RDFS->comment, $RDFS->range, $RDFS->Literal),
	statement($RDFS->label, $RDFS->range, $RDFS->Literal),
	statement($RDF->value, $RDFS->range, $RDFS->Resource),

	statement($RDF->Alt, $RDFS->subClassOf, $RDFS->Container),
	statement($RDF->Bag, $RDFS->subClassOf, $RDFS->Container),
	statement($RDF->Seq, $RDFS->subClassOf, $RDFS->Container),
	statement($RDFS->ContainerMembershipProperty, $RDFS->subClassOf, $RDF->Property),

	statement($RDFS->isDefinedBy, $RDFS->subPropertyOf, $RDFS->seeAlso),

	statement($RDF->XMLLiteral, $RDF->type, $RDFS->Datatype),
	statement($RDF->XMLLiteral, $RDFS->subClassOf, $RDFS->Literal),
	statement($RDFS->Datatype, $RDFS->subClassOf, $RDFS->Class),

	# rdfs valid triples; these would be inferred by the RDFS expansion, but it may make things
	# a bit faster to add these upfront
	statement($RDFS->Resource, $RDF->type, $RDFS->Class),
	statement($RDFS->Class, $RDF->type, $RDFS->Class),
	statement($RDFS->Literal, $RDF->type, $RDFS->Class),
	statement($RDF->XMLLiteral, $RDF->type, $RDFS->Class),
	statement($RDFS->Datatype, $RDF->type, $RDFS->Class),
	statement($RDF->Seq, $RDF->type, $RDFS->Class),
	statement($RDF->Bag, $RDF->type, $RDFS->Class),
	statement($RDF->Alt, $RDF->type, $RDFS->Class),
	statement($RDFS->Container, $RDF->type, $RDFS->Class),
	statement($RDF->List, $RDF->type, $RDFS->Class),
	statement($RDFS->ContainerMembershipProperty, $RDF->type, $RDFS->Class),
	statement($RDF->Property, $RDF->type, $RDFS->Class),
	statement($RDF->Statement, $RDF->type, $RDFS->Class),

	statement($RDFS->domain, $RDF->type, $RDF->Property),
	statement($RDFS->range, $RDF->type, $RDF->Property),
	statement($RDFS->subPropertyOf, $RDF->type, $RDF->Property),
	statement($RDFS->subClassOf, $RDF->type, $RDF->Property),
	statement($RDFS->member, $RDF->type, $RDF->Property),
	statement($RDFS->seeAlso, $RDF->type, $RDF->Property),
	statement($RDFS->isDefinedBy, $RDF->type, $RDF->Property),
	statement($RDFS->comment, $RDF->type, $RDF->Property),
	statement($RDFS->label, $RDF->type, $RDF->Property),
];

#: RDFS Axiomatic Triples all together
our $RDFS_Axiomatic_Triples = [@$_Simple_RDF_axiomatic_triples, @$_RDFS_axiomatic_triples];

#: RDFS D-entailement triples, ie, possible subclassing of various datatypes
our $RDFS_D_Axiomatic_Triples_subclasses = [
	# See http://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#built-in-datatypes
	statement($XSD->decimal, $RDFS->subClassOf, $RDFS->Literal),

	statement($XSD->integer, $RDFS->subClassOf, $XSD->decimal),

	statement($XSD->long, $RDFS->subClassOf, $XSD->integer),
	statement($XSD->int, $RDFS->subClassOf, $XSD->long),
	statement($XSD->short, $RDFS->subClassOf, $XSD->int),
	statement($XSD->byte, $RDFS->subClassOf, $XSD->short),

	statement($XSD->nonNegativeInteger, $RDFS->subClassOf, $XSD->integer),
	statement($XSD->positiveInteger, $RDFS->subClassOf, $XSD->nonNegativeInteger),
	statement($XSD->unsignedLong, $RDFS->subClassOf, $XSD->nonNegativeInteger),
	statement($XSD->unsignedInt, $RDFS->subClassOf, $XSD->unsignedLong),
	statement($XSD->unsignedShort, $RDFS->subClassOf, $XSD->unsignedInt),
	statement($XSD->unsignedByte, $RDFS->subClassOf, $XSD->unsignedShort),

	statement($XSD->nonPositiveInteger, $RDFS->subClassOf, $XSD->integer),
	statement($XSD->negativeInteger, $RDFS->subClassOf, $XSD->nonPositiveInteger),

	statement($XSD->normalizedString, $RDFS->subClassOf, $XSD->string),
	statement($XSD->token, $RDFS->subClassOf, $XSD->normalizedString),
	statement($XSD->language, $RDFS->subClassOf, $XSD->token),
	statement($XSD->Name, $RDFS->subClassOf, $XSD->token),
	statement($XSD->NMTOKEN, $RDFS->subClassOf, $XSD->token),

	statement($XSD->NCName, $RDFS->subClassOf, $XSD->Name),

	statement($XSD->dateTimeStamp, $RDFS->subClassOf, $XSD->dateTime),
];

our $RDFS_D_Axiomatic_Triples_types = [
	statement($XSD->integer, $RDF->type, $RDFS->Datatype),
	statement($XSD->decimal, $RDF->type, $RDFS->Datatype),
	statement($XSD->nonPositiveInteger, $RDF->type, $RDFS->Datatype),
	statement($XSD->nonPositiveInteger, $RDF->type, $RDFS->Datatype),
	statement($XSD->positiveInteger, $RDF->type, $RDFS->Datatype),
	statement($XSD->positiveInteger, $RDF->type, $RDFS->Datatype),
	statement($XSD->long, $RDF->type, $RDFS->Datatype),
	statement($XSD->int, $RDF->type, $RDFS->Datatype),
	statement($XSD->short, $RDF->type, $RDFS->Datatype),
	statement($XSD->byte, $RDF->type, $RDFS->Datatype),
	statement($XSD->unsignedLong, $RDF->type, $RDFS->Datatype),
	statement($XSD->unsignedInt, $RDF->type, $RDFS->Datatype),
	statement($XSD->unsignedShort, $RDF->type, $RDFS->Datatype),
	statement($XSD->unsignedByte, $RDF->type, $RDFS->Datatype),
	statement($XSD->float, $RDF->type, $RDFS->Datatype),
	statement($XSD->double, $RDF->type, $RDFS->Datatype),
	statement($XSD->string, $RDF->type, $RDFS->Datatype),
	statement($XSD->normalizedString, $RDF->type, $RDFS->Datatype),
	statement($XSD->token, $RDF->type, $RDFS->Datatype),
	statement($XSD->language, $RDF->type, $RDFS->Datatype),
	statement($XSD->Name, $RDF->type, $RDFS->Datatype),
	statement($XSD->NCName, $RDF->type, $RDFS->Datatype),
	statement($XSD->NMTOKEN, $RDF->type, $RDFS->Datatype),
	statement($XSD->boolean, $RDF->type, $RDFS->Datatype),
	statement($XSD->hexBinary, $RDF->type, $RDFS->Datatype),
	statement($XSD->base64Binary, $RDF->type, $RDFS->Datatype),
	statement($XSD->anyURI, $RDF->type, $RDFS->Datatype),
	statement($XSD->dateTimeStamp, $RDF->type, $RDFS->Datatype),
	statement($XSD->dateTime, $RDF->type, $RDFS->Datatype),
	statement($RDFS->Literal, $RDF->type, $RDFS->Datatype),
	statement($RDF->XMLLiteral, $RDF->type, $RDFS->Datatype),
];

our $RDFS_D_Axiomatic_Triples = [@$RDFS_D_Axiomatic_Triples_types, @$RDFS_D_Axiomatic_Triples_subclasses];

#: OWL $RDFS->Class axiomatic triples: definition of special classes
our $_OWL_axiomatic_triples_Classes = [
	statement($OWL->AllDifferent, $RDF->type, $RDFS->Class),
	statement($OWL->AllDifferent, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->AllDisjointClasses, $RDF->type, $RDFS->Class),
	statement($OWL->AllDisjointClasses, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->AllDisjointProperties, $RDF->type, $RDFS->Class),
	statement($OWL->AllDisjointProperties, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->Annotation, $RDF->type, $RDFS->Class),
	statement($OWL->Annotation, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->AnnotationProperty, $RDF->type, $RDFS->Class),
	statement($OWL->AnnotationProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->AsymmetricProperty, $RDF->type, $RDFS->Class),
	statement($OWL->AsymmetricProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->Class, $RDF->type, $RDFS->Class),
	statement($OWL->Class, $OWL->equivalentClass, $RDFS->Class),

#	statement($OWL->DataRange, $RDF->type, $RDFS->Class),
#	statement($OWL->DataRange, $OWL->equivalentClass, $RDFS->Datatype),

	statement($RDFS->Datatype, $RDF->type, $RDFS->Class),

	statement($OWL->DatatypeProperty, $RDF->type, $RDFS->Class),
	statement($OWL->DatatypeProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->DeprecatedClass, $RDF->type, $RDFS->Class),
	statement($OWL->DeprecatedClass, $RDFS->subClassOf, $RDFS->Class),

	statement($OWL->DeprecatedProperty, $RDF->type, $RDFS->Class),
	statement($OWL->DeprecatedProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->FunctionalProperty, $RDF->type, $RDFS->Class),
	statement($OWL->FunctionalProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->InverseFunctionalProperty, $RDF->type, $RDFS->Class),
	statement($OWL->InverseFunctionalProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->IrreflexiveProperty, $RDF->type, $RDFS->Class),
	statement($OWL->IrreflexiveProperty, $RDFS->subClassOf, $RDF->Property),

	statement($RDFS->Literal, $RDF->type, $RDFS->Datatype),

#	statement($OWL->NamedIndividual, $RDF->type, $RDFS->Class),
#	statement($OWL->NamedIndividual, $OWL->equivalentClass, $RDFS->Resource),

	statement($OWL->NegativePropertyAssertion, $RDF->type, $RDFS->Class),
	statement($OWL->NegativePropertyAssertion, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->Nothing, $RDF->type, $RDFS->Class),
	statement($OWL->Nothing, $RDFS->subClassOf, $OWL->Thing ),

	statement($OWL->ObjectProperty, $RDF->type, $RDFS->Class),
	statement($OWL->ObjectProperty, $OWL->equivalentClass, $RDF->Property),

	statement($OWL->Ontology, $RDF->type, $RDFS->Class),
	statement($OWL->Ontology, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->OntologyProperty, $RDF->type, $RDFS->Class),
	statement($OWL->OntologyProperty, $RDFS->subClassOf, $RDF->Property),

	statement($RDF->Property, $RDF->type, $RDFS->Class),

	statement($OWL->ReflexiveProperty, $RDF->type, $RDFS->Class),
	statement($OWL->ReflexiveProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->Restriction, $RDF->type, $RDFS->Class),
	statement($OWL->Restriction, $RDFS->subClassOf, $RDFS->Class),


	statement($OWL->SymmetricProperty, $RDF->type, $RDFS->Class),
	statement($OWL->SymmetricProperty, $RDFS->subClassOf, $RDF->Property),

	statement($OWL->Thing, $RDF->type, $RDFS->Class),
	statement($OWL->Thing, $RDFS->subClassOf, $RDFS->Resource),

	statement($OWL->TransitiveProperty, $RDF->type, $RDFS->Class),
	statement($OWL->TransitiveProperty, $RDFS->subClassOf, $RDF->Property),

	# OWL valid triples; some of these would be inferred by the OWL RL expansion, but it may make things
	# a bit faster to add these upfront
	statement($OWL->AllDisjointProperties, $RDF->type, $OWL->Class),
	statement($OWL->AllDisjointClasses, $RDF->type, $OWL->Class),
	statement($OWL->AllDisjointProperties, $RDF->type, $OWL->Class),
	statement($OWL->Annotation, $RDF->type, $OWL->Class),
	statement($OWL->AsymmetricProperty, $RDF->type, $OWL->Class),
	statement($OWL->Axiom, $RDF->type, $OWL->Class),
	statement($OWL->DataRange, $RDF->type, $OWL->Class),
	statement($RDFS->Datatype, $RDF->type, $OWL->Class),
	statement($OWL->DatatypeProperty, $RDF->type, $OWL->Class),
	statement($OWL->DeprecatedClass, $RDF->type, $OWL->Class),
	statement($OWL->DeprecatedClass, $RDFS->subClassOf, $OWL->Class),
	statement($OWL->DeprecatedProperty, $RDF->type, $OWL->Class),
	statement($OWL->FunctionalProperty, $RDF->type, $OWL->Class),
	statement($OWL->InverseFunctionalProperty, $RDF->type, $OWL->Class),
	statement($OWL->IrreflexiveProperty, $RDF->type, $OWL->Class),
	statement($OWL->NamedIndividual, $RDF->type, $OWL->Class),
	statement($OWL->NegativePropertyAssertion, $RDF->type, $OWL->Class),
	statement($OWL->Nothing, $RDF->type, $OWL->Class),
	statement($OWL->ObjectProperty, $RDF->type, $OWL->Class),
	statement($OWL->Ontology, $RDF->type, $OWL->Class),
	statement($OWL->OntologyProperty, $RDF->type, $OWL->Class),
	statement($RDF->Property, $RDF->type, $OWL->Class),
	statement($OWL->ReflexiveProperty, $RDF->type, $OWL->Class),
	statement($OWL->Restriction, $RDF->type, $OWL->Class),
	statement($OWL->Restriction, $RDFS->subClassOf, $OWL->Class),
#	statement(SelfRestriction, $RDF->type, $OWL->Class),
	statement($OWL->SymmetricProperty, $RDF->type, $OWL->Class),
	statement($OWL->Thing, $RDF->type, $OWL->Class),
	statement($OWL->TransitiveProperty, $RDF->type, $OWL->Class),
];

#: OWL $RDF->Property axiomatic triples: definition of domains and ranges
our $_OWL_axiomatic_triples_Properties = [
	statement($OWL->allValuesFrom, $RDF->type, $RDF->Property),
	statement($OWL->allValuesFrom, $RDFS->domain, $OWL->Restriction),
	statement($OWL->allValuesFrom, $RDFS->range, $RDFS->Class),

	statement($OWL->assertionProperty, $RDF->type, $RDF->Property),
	statement($OWL->assertionProperty, $RDFS->domain, $OWL->NegativePropertyAssertion),
	statement($OWL->assertionProperty, $RDFS->range, $RDF->Property),

	statement($OWL->backwardCompatibleWith, $RDF->type, $OWL->OntologyProperty),
	statement($OWL->backwardCompatibleWith, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->backwardCompatibleWith, $RDFS->domain, $OWL->Ontology),
	statement($OWL->backwardCompatibleWith, $RDFS->range, $OWL->Ontology),

#	statement($OWL->bottomDataProperty, $RDF->type, DatatypeProperty),
#
#	statement($OWL->bottomObjectProperty, $RDF->type, ObjectProperty),

#	statement($OWL->cardinality, $RDF->type, $RDF->Property),
#	statement($OWL->cardinality, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->cardinality, $RDFS->range, $XSD->nonNegativeInteger),

	statement($RDFS->comment, $RDF->type, $OWL->AnnotationProperty),
	statement($RDFS->comment, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->comment, $RDFS->range, $RDFS->Literal),

	statement($OWL->complementOf, $RDF->type, $RDF->Property),
	statement($OWL->complementOf, $RDFS->domain, $RDFS->Class),
	statement($OWL->complementOf, $RDFS->range, $RDFS->Class),

#
#	statement($OWL->datatypeComplementOf, $RDF->type, $RDF->Property),
#	statement($OWL->datatypeComplementOf, $RDFS->domain, $RDFS->Datatype),
#	statement($OWL->datatypeComplementOf, $RDFS->range, $RDFS->Datatype),

	statement($OWL->deprecated, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->deprecated, $RDFS->domain, $RDFS->Resource),
	statement($OWL->deprecated, $RDFS->range, $RDFS->Resource),

	statement($OWL->differentFrom, $RDF->type, $RDF->Property),
	statement($OWL->differentFrom, $RDFS->domain, $RDFS->Resource),
	statement($OWL->differentFrom, $RDFS->range, $RDFS->Resource),

#	statement($OWL->disjointUnionOf, $RDF->type, $RDF->Property),
#	statement($OWL->disjointUnionOf, $RDFS->domain, $RDFS->Class),
#	statement($OWL->disjointUnionOf, $RDFS->range, $RDF->List),

	statement($OWL->disjointWith, $RDF->type, $RDF->Property),
	statement($OWL->disjointWith, $RDFS->domain, $RDFS->Class),
	statement($OWL->disjointWith, $RDFS->range, $RDFS->Class),

	statement($OWL->distinctMembers, $RDF->type, $RDF->Property),
	statement($OWL->distinctMembers, $RDFS->domain, $OWL->AllDifferent),
	statement($OWL->distinctMembers, $RDFS->range, $RDF->List),

	statement($OWL->equivalentClass, $RDF->type, $RDF->Property),
	statement($OWL->equivalentClass, $RDFS->domain, $RDFS->Class),
	statement($OWL->equivalentClass, $RDFS->range, $RDFS->Class),

	statement($OWL->equivalentProperty, $RDF->type, $RDF->Property),
	statement($OWL->equivalentProperty, $RDFS->domain, $RDF->Property),
	statement($OWL->equivalentProperty, $RDFS->range, $RDF->Property),

	statement($OWL->hasKey, $RDF->type, $RDF->Property),
	statement($OWL->hasKey, $RDFS->domain, $RDFS->Class),
	statement($OWL->hasKey, $RDFS->range, $RDF->List),

	statement($OWL->hasValue, $RDF->type, $RDF->Property),
	statement($OWL->hasValue, $RDFS->domain, $OWL->Restriction),
	statement($OWL->hasValue, $RDFS->range, $RDFS->Resource),

	statement($OWL->imports, $RDF->type, $OWL->OntologyProperty),
	statement($OWL->imports, $RDFS->domain, $OWL->Ontology),
	statement($OWL->imports, $RDFS->range, $OWL->Ontology),

	statement($OWL->incompatibleWith, $RDF->type, $OWL->OntologyProperty),
	statement($OWL->incompatibleWith, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->incompatibleWith, $RDFS->domain, $OWL->Ontology),
	statement($OWL->incompatibleWith, $RDFS->range, $OWL->Ontology),

	statement($OWL->intersectionOf, $RDF->type, $RDF->Property),
	statement($OWL->intersectionOf, $RDFS->domain, $RDFS->Class),
	statement($OWL->intersectionOf, $RDFS->range, $RDF->List),

	statement($OWL->inverseOf, $RDF->type, $RDF->Property),
	statement($OWL->inverseOf, $RDFS->domain, $RDF->Property),
	statement($OWL->inverseOf, $RDFS->range, $RDF->Property),

	statement($RDFS->isDefinedBy, $RDF->type, $OWL->AnnotationProperty),
	statement($RDFS->isDefinedBy, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->isDefinedBy, $RDFS->range, $RDFS->Resource),

	statement($RDFS->label, $RDF->type, $OWL->AnnotationProperty),
	statement($RDFS->label, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->label, $RDFS->range, $RDFS->Literal),

	statement($OWL->maxCardinality, $RDF->type, $RDF->Property),
	statement($OWL->maxCardinality, $RDFS->domain, $OWL->Restriction),
	statement($OWL->maxCardinality, $RDFS->range, $XSD->nonNegativeInteger),

	statement($OWL->maxQualifiedCardinality, $RDF->type, $RDF->Property),
	statement($OWL->maxQualifiedCardinality, $RDFS->domain, $OWL->Restriction),
	statement($OWL->maxQualifiedCardinality, $RDFS->range, $XSD->nonNegativeInteger),

	statement($OWL->members, $RDF->type, $RDF->Property),
	statement($OWL->members, $RDFS->domain, $RDFS->Resource),
	statement($OWL->members, $RDFS->range, $RDF->List),

#	statement($OWL->minCardinality, $RDF->type, $RDF->Property),
#	statement($OWL->minCardinality, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->minCardinality, $RDFS->range, $XSD->nonNegativeInteger),

#	statement($OWL->minQualifiedCardinality, $RDF->type, $RDF->Property),
#	statement($OWL->minQualifiedCardinality, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->minQualifiedCardinality, $RDFS->range, $XSD->nonNegativeInteger),

#	statement($OWL->annotatedTarget, $RDF->type, $RDF->Property),
#	statement($OWL->annotatedTarget, $RDFS->domain, $RDFS->Resource),
#	statement($OWL->annotatedTarget, $RDFS->range, $RDFS->Resource),

	statement($OWL->onClass, $RDF->type, $RDF->Property),
	statement($OWL->onClass, $RDFS->domain, $OWL->Restriction),
	statement($OWL->onClass, $RDFS->range, $RDFS->Class),

#	statement($OWL->onDataRange, $RDF->type, $RDF->Property),
#	statement($OWL->onDataRange, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->onDataRange, $RDFS->range, $RDFS->Datatype),

	statement($OWL->onDatatype, $RDF->type, $RDF->Property),
	statement($OWL->onDatatype, $RDFS->domain, $RDFS->Datatype),
	statement($OWL->onDatatype, $RDFS->range, $RDFS->Datatype),

	statement($OWL->oneOf, $RDF->type, $RDF->Property),
	statement($OWL->oneOf, $RDFS->domain, $RDFS->Class),
	statement($OWL->oneOf, $RDFS->range, $RDF->List),

	statement($OWL->onProperty, $RDF->type, $RDF->Property),
	statement($OWL->onProperty, $RDFS->domain, $OWL->Restriction),
	statement($OWL->onProperty, $RDFS->range, $RDF->Property),

#	statement($OWL->onProperties, $RDF->type, $RDF->Property),
#	statement($OWL->onProperties, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->onProperties, $RDFS->range, $RDF->List),

#	statement($OWL->annotatedProperty, $RDF->type, $RDF->Property),
#	statement($OWL->annotatedProperty, $RDFS->domain, $RDFS->Resource),
#	statement($OWL->annotatedProperty, $RDFS->range, $RDF->Property),

	statement($OWL->priorVersion, $RDF->type, $OWL->OntologyProperty),
	statement($OWL->priorVersion, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->priorVersion, $RDFS->domain, $OWL->Ontology),
	statement($OWL->priorVersion, $RDFS->range, $OWL->Ontology),

	statement($OWL->propertyChainAxiom, $RDF->type, $RDF->Property),
	statement($OWL->propertyChainAxiom, $RDFS->domain, $RDF->Property),
	statement($OWL->propertyChainAxiom, $RDFS->range, $RDF->List),

#	statement($OWL->propertyDisjointWith, $RDF->type, $RDF->Property),
#	statement($OWL->propertyDisjointWith, $RDFS->domain, $RDF->Property),
#	statement($OWL->propertyDisjointWith, $RDFS->range, $RDF->Property),
#
#	statement($OWL->qualifiedCardinality, $RDF->type, $RDF->Property),
#	statement($OWL->qualifiedCardinality, $RDFS->domain, $OWL->Restriction),
#	statement($OWL->qualifiedCardinality, $RDFS->range, $XSD->nonNegativeInteger),

	statement($OWL->sameAs, $RDF->type, $RDF->Property),
	statement($OWL->sameAs, $RDFS->domain, $RDFS->Resource),
	statement($OWL->sameAs, $RDFS->range, $RDFS->Resource),

	statement($RDFS->seeAlso, $RDF->type, $OWL->AnnotationProperty),
	statement($RDFS->seeAlso, $RDFS->domain, $RDFS->Resource),
	statement($RDFS->seeAlso, $RDFS->range, $RDFS->Resource),

	statement($OWL->someValuesFrom, $RDF->type, $RDF->Property),
	statement($OWL->someValuesFrom, $RDFS->domain, $OWL->Restriction),
	statement($OWL->someValuesFrom, $RDFS->range, $RDFS->Class),

	statement($OWL->sourceIndividual, $RDF->type, $RDF->Property),
	statement($OWL->sourceIndividual, $RDFS->domain, $OWL->NegativePropertyAssertion),
	statement($OWL->sourceIndividual, $RDFS->range, $RDFS->Resource),
#
#	statement($OWL->annotatedSource, $RDF->type, $RDF->Property),
#	statement($OWL->annotatedSource, $RDFS->domain, $RDFS->Resource),
#	statement($OWL->annotatedSource, $RDFS->range, $RDFS->Resource),
#
	statement($OWL->targetIndividual, $RDF->type, $RDF->Property),
	statement($OWL->targetIndividual, $RDFS->domain, $OWL->NegativePropertyAssertion),
	statement($OWL->targetIndividual, $RDFS->range, $RDFS->Resource),

	statement($OWL->targetValue, $RDF->type, $RDF->Property),
	statement($OWL->targetValue, $RDFS->domain, $OWL->NegativePropertyAssertion),
	statement($OWL->targetValue, $RDFS->range, $RDFS->Literal),

#	statement($OWL->topDataProperty, $RDF->type, DatatypeProperty),
#	statement($OWL->topDataProperty, $RDFS->domain, $RDFS->Resource),
#	statement($OWL->topDataProperty, $RDFS->range, $RDFS->Literal),
#
#	statement($OWL->topObjectProperty, $RDF->type, ObjectProperty),
#	statement($OWL->topObjectProperty, $RDFS->domain, $RDFS->Resource),
#	statement($OWL->topObjectProperty, $RDFS->range, $RDFS->Resource),

	statement($OWL->unionOf, $RDF->type, $RDF->Property),
	statement($OWL->unionOf, $RDFS->domain, $RDFS->Class),
	statement($OWL->unionOf, $RDFS->range, $RDF->List),

	statement($OWL->versionInfo, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->versionInfo, $RDFS->domain, $RDFS->Resource),
	statement($OWL->versionInfo, $RDFS->range, $RDFS->Resource),

	statement($OWL->versionIRI, $RDF->type, $OWL->AnnotationProperty),
	statement($OWL->versionIRI, $RDFS->domain, $RDFS->Resource),
	statement($OWL->versionIRI, $RDFS->range, $RDFS->Resource),

	statement($OWL->withRestrictions, $RDF->type, $RDF->Property),
	statement($OWL->withRestrictions, $RDFS->domain, $RDFS->Datatype),
	statement($OWL->withRestrictions, $RDFS->range, $RDF->List),

	# some OWL valid triples; these would be inferred by the OWL RL expansion, but it may make things
	# a bit faster to add these upfront
	statement($OWL->allValuesFrom, $RDFS->range, $OWL->Class),
	statement($OWL->complementOf, $RDFS->domain, $OWL->Class),
	statement($OWL->complementOf, $RDFS->range, $OWL->Class),

#	statement($OWL->datatypeComplementOf, $RDFS->domain, $OWL->DataRange),
#	statement($OWL->datatypeComplementOf, $RDFS->range, $OWL->DataRange),
	statement($OWL->disjointUnionOf, $RDFS->domain, $OWL->Class),
	statement($OWL->disjointWith, $RDFS->domain, $OWL->Class),
	statement($OWL->disjointWith, $RDFS->range, $OWL->Class),
	statement($OWL->equivalentClass, $RDFS->domain, $OWL->Class),
	statement($OWL->equivalentClass, $RDFS->range, $OWL->Class),
	statement($OWL->hasKey, $RDFS->domain, $OWL->Class),
	statement($OWL->intersectionOf, $RDFS->domain, $OWL->Class),
	statement($OWL->onClass, $RDFS->range, $OWL->Class),
#	statement($OWL->onDataRange, $RDFS->range, $OWL->DataRange),
	statement($OWL->onDatatype, $RDFS->domain, $OWL->DataRange),
	statement($OWL->onDatatype, $RDFS->range, $OWL->DataRange),
	statement($OWL->oneOf, $RDFS->domain, $OWL->Class),
	statement($OWL->someValuesFrom, $RDFS->range, $OWL->Class),
	statement($OWL->unionOf, $RDFS->range, $OWL->Class),
#	statement($OWL->withRestrictions, $RDFS->domain, $OWL->DataRange)
];

#: OWL RL axiomatic triples: combination of the RDFS triples plus the OWL specific ones
our $OWLRL_Axiomatic_Triples   = [@$_OWL_axiomatic_triples_Classes, @$_OWL_axiomatic_triples_Properties];

# Note that this is not used anywhere. But I encoded it once and I did not want to remove it...:-)
our $_OWL_axiomatic_triples_Facets = [
	# langPattern
	statement($XSD->length,$RDF->type,$RDF->Property),
	statement($XSD->maxExclusive,$RDF->type,$RDF->Property),
	statement($XSD->maxInclusive,$RDF->type,$RDF->Property),
	statement($XSD->maxLength,$RDF->type,$RDF->Property),
	statement($XSD->minExclusive,$RDF->type,$RDF->Property),
	statement($XSD->minInclusive,$RDF->type,$RDF->Property),
	statement($XSD->minLength,$RDF->type,$RDF->Property),
	statement($XSD->pattern,$RDF->type,$RDF->Property),

	statement($XSD->length,$RDFS->domain,$RDFS->Resource),
	statement($XSD->maxExclusive,$RDFS->domain,$RDFS->Resource),
	statement($XSD->maxInclusive,$RDFS->domain,$RDFS->Resource),
	statement($XSD->maxLength,$RDFS->domain,$RDFS->Resource),
	statement($XSD->minExclusive,$RDFS->domain,$RDFS->Resource),
	statement($XSD->minInclusive,$RDFS->domain,$RDFS->Resource),
	statement($XSD->minLength,$RDFS->domain,$RDFS->Resource),
	statement($XSD->pattern,$RDFS->domain,$RDFS->Resource),
	statement($XSD->length,$RDFS->domain,$RDFS->Resource),

	statement($XSD->maxExclusive,$RDFS->range,$RDFS->Literal),
	statement($XSD->maxInclusive,$RDFS->range,$RDFS->Literal),
	statement($XSD->maxLength,$RDFS->range,$RDFS->Literal),
	statement($XSD->minExclusive,$RDFS->range,$RDFS->Literal),
	statement($XSD->minInclusive,$RDFS->range,$RDFS->Literal),
	statement($XSD->minLength,$RDFS->range,$RDFS->Literal),
	statement($XSD->pattern,$RDFS->range,$RDFS->Literal),
];

#: OWL D-entailement triples statement(additionally to the RDFS ones), ie, possible subclassing of various extra datatypes
our $_OWL_D_Axiomatic_Triples_types = [
	statement($RDF->PlainLiteral, $RDF->type, $RDFS->Datatype)
];

our $OWL_D_Axiomatic_Triples_subclasses = [
	statement($XSD->string, $RDFS->subClassOf, $RDF->PlainLiteral),
	statement($XSD->normalizedString, $RDFS->subClassOf, $RDF->PlainLiteral),
	statement($XSD->token, $RDFS->subClassOf, $RDF->PlainLiteral),
	statement($XSD->Name, $RDFS->subClassOf, $RDF->PlainLiteral),
	statement($XSD->NCName, $RDFS->subClassOf, $RDF->PlainLiteral),
	statement($XSD->NMTOKEN, $RDFS->subClassOf, $RDF->PlainLiteral)
];

our $OWLRL_Datatypes_Disjointness = [
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->base64Binary),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->boolean),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->dateTime),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->decimal),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->double),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->float),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->anyURI, $OWL->disjointWith, $XSD->string),
	statement($XSD->anyURI, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->anyURI, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->boolean),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->dateTime),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->decimal),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->double),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->float),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->base64Binary, $OWL->disjointWith, $XSD->string),
	statement($XSD->base64Binary, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->base64Binary, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->boolean, $OWL->disjointWith, $XSD->dateTime),
	statement($XSD->boolean, $OWL->disjointWith, $XSD->decimal),
	statement($XSD->boolean, $OWL->disjointWith, $XSD->double),
	statement($XSD->boolean, $OWL->disjointWith, $XSD->float),
	statement($XSD->boolean, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->boolean, $OWL->disjointWith, $XSD->string),
	statement($XSD->boolean, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->boolean, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->dateTime, $OWL->disjointWith, $XSD->decimal),
	statement($XSD->dateTime, $OWL->disjointWith, $XSD->double),
	statement($XSD->dateTime, $OWL->disjointWith, $XSD->float),
	statement($XSD->dateTime, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->dateTime, $OWL->disjointWith, $XSD->string),
	statement($XSD->dateTime, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->dateTime, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->decimal, $OWL->disjointWith, $XSD->double),
	statement($XSD->decimal, $OWL->disjointWith, $XSD->float),
	statement($XSD->decimal, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->decimal, $OWL->disjointWith, $XSD->string),
	statement($XSD->decimal, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->decimal, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->double, $OWL->disjointWith, $XSD->float),
	statement($XSD->double, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->double, $OWL->disjointWith, $XSD->string),
	statement($XSD->double, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->double, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->float, $OWL->disjointWith, $XSD->hexBinary),
	statement($XSD->float, $OWL->disjointWith, $XSD->string),
	statement($XSD->float, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->float, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->hexBinary, $OWL->disjointWith, $XSD->string),
	statement($XSD->hexBinary, $OWL->disjointWith, $RDF->PlainLiteral),
	statement($XSD->hexBinary, $OWL->disjointWith, $RDF->XMLLiteral),

	statement($XSD->string, $OWL->disjointWith, $RDF->XMLLiteral),
];

#: OWL RL D Axiomatic triples: combination of the RDFS ones, plus some extra statements on ranges and domains, plus some OWL specific datatypes
our $OWLRL_D_Axiomatic_Triples = [@$RDFS_D_Axiomatic_Triples, @$_OWL_D_Axiomatic_Triples_types, @$OWL_D_Axiomatic_Triples_subclasses, @$OWLRL_Datatypes_Disjointness];

1;

=head1 NAME

RDF::Closure::AxiomaticTriples - exports lists of axiomatic triples

=head1 ANALOGOUS PYTHON

RDFClosure/AxiomaticTriples.py

=head1 SEE ALSO

L<RDF::Closure>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2011 Ivan Herman

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

