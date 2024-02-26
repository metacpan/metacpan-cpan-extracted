package RDF::Cowl::Lib::Gen::Types;
# ABSTRACT: Private class for FFI::Platypus types
$RDF::Cowl::Lib::Gen::Types::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Types.pm.tt

use strict;
use warnings;
use RDF::Cowl::Lib;

my $ffi = RDF::Cowl::Lib->ffi;

$ffi->type( "object(RDF::Cowl::AnnotAssertAxiom)" => "CowlAnnotAssertAxiom" );
$ffi->type( "object(RDF::Cowl::AnnotProp)" => "CowlAnnotProp" );
$ffi->type( "object(RDF::Cowl::AnnotPropDomainAxiom)" => "CowlAnnotPropDomainAxiom" );
$ffi->type( "object(RDF::Cowl::AnnotPropRangeAxiom)" => "CowlAnnotPropRangeAxiom" );
$ffi->type( "object(RDF::Cowl::AnnotValue)" => "CowlAnnotValue" );
$ffi->type( "object(RDF::Cowl::Annotation)" => "CowlAnnotation" );
$ffi->type( "object(RDF::Cowl::AnonInd)" => "CowlAnonInd" );
$ffi->type( "object(RDF::Cowl::Class)" => "CowlClass" );
$ffi->type( "object(RDF::Cowl::ClsAssertAxiom)" => "CowlClsAssertAxiom" );
$ffi->type( "object(RDF::Cowl::ClsExp)" => "CowlClsExp" );
$ffi->type( "object(RDF::Cowl::DataCard)" => "CowlDataCard" );
$ffi->type( "object(RDF::Cowl::DataCompl)" => "CowlDataCompl" );
$ffi->type( "object(RDF::Cowl::DataHasValue)" => "CowlDataHasValue" );
$ffi->type( "object(RDF::Cowl::DataOneOf)" => "CowlDataOneOf" );
$ffi->type( "object(RDF::Cowl::DataProp)" => "CowlDataProp" );
$ffi->type( "object(RDF::Cowl::DataPropAssertAxiom)" => "CowlDataPropAssertAxiom" );
$ffi->type( "object(RDF::Cowl::DataPropDomainAxiom)" => "CowlDataPropDomainAxiom" );
$ffi->type( "object(RDF::Cowl::DataPropExp)" => "CowlDataPropExp" );
$ffi->type( "object(RDF::Cowl::DataPropRangeAxiom)" => "CowlDataPropRangeAxiom" );
$ffi->type( "object(RDF::Cowl::DataQuant)" => "CowlDataQuant" );
$ffi->type( "object(RDF::Cowl::DataRange)" => "CowlDataRange" );
$ffi->type( "object(RDF::Cowl::Datatype)" => "CowlDatatype" );
$ffi->type( "object(RDF::Cowl::DatatypeDefAxiom)" => "CowlDatatypeDefAxiom" );
$ffi->type( "object(RDF::Cowl::DatatypeRestr)" => "CowlDatatypeRestr" );
$ffi->type( "object(RDF::Cowl::DeclAxiom)" => "CowlDeclAxiom" );
$ffi->type( "object(RDF::Cowl::DisjUnionAxiom)" => "CowlDisjUnionAxiom" );
$ffi->type( "object(RDF::Cowl::Entity)" => "CowlEntity" );
$ffi->type( "object(RDF::Cowl::Error)" => "CowlError" );
$ffi->type( "object(RDF::Cowl::FacetRestr)" => "CowlFacetRestr" );
$ffi->type( "object(RDF::Cowl::FuncDataPropAxiom)" => "CowlFuncDataPropAxiom" );
$ffi->type( "object(RDF::Cowl::HasKeyAxiom)" => "CowlHasKeyAxiom" );
$ffi->type( "object(RDF::Cowl::IRI)" => "CowlIRI" );
$ffi->type( "object(RDF::Cowl::IStream)" => "CowlIStream" );
$ffi->type( "object(RDF::Cowl::Individual)" => "CowlIndividual" );
$ffi->type( "object(RDF::Cowl::InvObjProp)" => "CowlInvObjProp" );
$ffi->type( "object(RDF::Cowl::InvObjPropAxiom)" => "CowlInvObjPropAxiom" );
$ffi->type( "object(RDF::Cowl::Literal)" => "CowlLiteral" );
$ffi->type( "object(RDF::Cowl::NAryBool)" => "CowlNAryBool" );
$ffi->type( "object(RDF::Cowl::NAryClsAxiom)" => "CowlNAryClsAxiom" );
$ffi->type( "object(RDF::Cowl::NAryData)" => "CowlNAryData" );
$ffi->type( "object(RDF::Cowl::NAryDataPropAxiom)" => "CowlNAryDataPropAxiom" );
$ffi->type( "object(RDF::Cowl::NAryIndAxiom)" => "CowlNAryIndAxiom" );
$ffi->type( "object(RDF::Cowl::NAryObjPropAxiom)" => "CowlNAryObjPropAxiom" );
$ffi->type( "object(RDF::Cowl::NamedInd)" => "CowlNamedInd" );
$ffi->type( "object(RDF::Cowl::OStream)" => "CowlOStream" );
$ffi->type( "object(RDF::Cowl::OWLVocab)" => "CowlOWLVocab" );
$ffi->type( "object(RDF::Cowl::ObjCard)" => "CowlObjCard" );
$ffi->type( "object(RDF::Cowl::ObjCompl)" => "CowlObjCompl" );
$ffi->type( "object(RDF::Cowl::ObjHasSelf)" => "CowlObjHasSelf" );
$ffi->type( "object(RDF::Cowl::ObjHasValue)" => "CowlObjHasValue" );
$ffi->type( "object(RDF::Cowl::ObjOneOf)" => "CowlObjOneOf" );
$ffi->type( "object(RDF::Cowl::ObjProp)" => "CowlObjProp" );
$ffi->type( "object(RDF::Cowl::ObjPropAssertAxiom)" => "CowlObjPropAssertAxiom" );
$ffi->type( "object(RDF::Cowl::ObjPropCharAxiom)" => "CowlObjPropCharAxiom" );
$ffi->type( "object(RDF::Cowl::ObjPropDomainAxiom)" => "CowlObjPropDomainAxiom" );
$ffi->type( "object(RDF::Cowl::ObjPropExp)" => "CowlObjPropExp" );
$ffi->type( "object(RDF::Cowl::ObjPropRangeAxiom)" => "CowlObjPropRangeAxiom" );
$ffi->type( "object(RDF::Cowl::ObjQuant)" => "CowlObjQuant" );
$ffi->type( "object(RDF::Cowl::RDFSVocab)" => "CowlRDFSVocab" );
$ffi->type( "object(RDF::Cowl::RDFVocab)" => "CowlRDFVocab" );
$ffi->type( "object(RDF::Cowl::SubAnnotPropAxiom)" => "CowlSubAnnotPropAxiom" );
$ffi->type( "object(RDF::Cowl::SubClsAxiom)" => "CowlSubClsAxiom" );
$ffi->type( "object(RDF::Cowl::SubDataPropAxiom)" => "CowlSubDataPropAxiom" );
$ffi->type( "object(RDF::Cowl::SubObjPropAxiom)" => "CowlSubObjPropAxiom" );
$ffi->type( "object(RDF::Cowl::SymTable)" => "CowlSymTable" );
$ffi->type( "object(RDF::Cowl::Table)" => "CowlTable" );
$ffi->type( "object(RDF::Cowl::Vector)" => "CowlVector" );
$ffi->type( "object(RDF::Cowl::XSDVocab)" => "CowlXSDVocab" );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Types - Private class for FFI::Platypus types

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
