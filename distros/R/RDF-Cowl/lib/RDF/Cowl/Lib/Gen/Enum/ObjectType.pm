package RDF::Cowl::Lib::Gen::Enum::ObjectType;
# ABSTRACT: Private class for RDF::Cowl::ObjectType
$RDF::Cowl::Lib::Gen::Enum::ObjectType::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Enum_OT.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjectType;

use strict;
use warnings;

our $_ENUM_CODES = [
  'COWL_OT_STRING',
  'COWL_OT_VECTOR',
  'COWL_OT_TABLE',
  'COWL_OT_IRI',
  'COWL_OT_LITERAL',
  'COWL_OT_FACET_RESTR',
  'COWL_OT_ONTOLOGY',
  'COWL_OT_MANAGER',
  'COWL_OT_SYM_TABLE',
  'COWL_OT_ISTREAM',
  'COWL_OT_OSTREAM',
  'COWL_OT_ANNOTATION',
  'COWL_OT_ANNOT_PROP',
  'COWL_OT_A_DECL',
  'COWL_OT_A_DATATYPE_DEF',
  'COWL_OT_A_SUB_CLASS',
  'COWL_OT_A_EQUIV_CLASSES',
  'COWL_OT_A_DISJ_CLASSES',
  'COWL_OT_A_DISJ_UNION',
  'COWL_OT_A_CLASS_ASSERT',
  'COWL_OT_A_SAME_IND',
  'COWL_OT_A_DIFF_IND',
  'COWL_OT_A_OBJ_PROP_ASSERT',
  'COWL_OT_A_NEG_OBJ_PROP_ASSERT',
  'COWL_OT_A_DATA_PROP_ASSERT',
  'COWL_OT_A_NEG_DATA_PROP_ASSERT',
  'COWL_OT_A_SUB_OBJ_PROP',
  'COWL_OT_A_INV_OBJ_PROP',
  'COWL_OT_A_EQUIV_OBJ_PROP',
  'COWL_OT_A_DISJ_OBJ_PROP',
  'COWL_OT_A_FUNC_OBJ_PROP',
  'COWL_OT_A_INV_FUNC_OBJ_PROP',
  'COWL_OT_A_SYMM_OBJ_PROP',
  'COWL_OT_A_ASYMM_OBJ_PROP',
  'COWL_OT_A_TRANS_OBJ_PROP',
  'COWL_OT_A_REFL_OBJ_PROP',
  'COWL_OT_A_IRREFL_OBJ_PROP',
  'COWL_OT_A_OBJ_PROP_DOMAIN',
  'COWL_OT_A_OBJ_PROP_RANGE',
  'COWL_OT_A_SUB_DATA_PROP',
  'COWL_OT_A_EQUIV_DATA_PROP',
  'COWL_OT_A_DISJ_DATA_PROP',
  'COWL_OT_A_FUNC_DATA_PROP',
  'COWL_OT_A_DATA_PROP_DOMAIN',
  'COWL_OT_A_DATA_PROP_RANGE',
  'COWL_OT_A_HAS_KEY',
  'COWL_OT_A_ANNOT_ASSERT',
  'COWL_OT_A_SUB_ANNOT_PROP',
  'COWL_OT_A_ANNOT_PROP_DOMAIN',
  'COWL_OT_A_ANNOT_PROP_RANGE',
  'COWL_OT_CE_CLASS',
  'COWL_OT_CE_OBJ_SOME',
  'COWL_OT_CE_OBJ_ALL',
  'COWL_OT_CE_OBJ_MIN_CARD',
  'COWL_OT_CE_OBJ_MAX_CARD',
  'COWL_OT_CE_OBJ_EXACT_CARD',
  'COWL_OT_CE_OBJ_HAS_VALUE',
  'COWL_OT_CE_OBJ_HAS_SELF',
  'COWL_OT_CE_DATA_SOME',
  'COWL_OT_CE_DATA_ALL',
  'COWL_OT_CE_DATA_MIN_CARD',
  'COWL_OT_CE_DATA_MAX_CARD',
  'COWL_OT_CE_DATA_EXACT_CARD',
  'COWL_OT_CE_DATA_HAS_VALUE',
  'COWL_OT_CE_OBJ_INTERSECT',
  'COWL_OT_CE_OBJ_UNION',
  'COWL_OT_CE_OBJ_COMPL',
  'COWL_OT_CE_OBJ_ONE_OF',
  'COWL_OT_DPE_DATA_PROP',
  'COWL_OT_DR_DATATYPE',
  'COWL_OT_DR_DATATYPE_RESTR',
  'COWL_OT_DR_DATA_INTERSECT',
  'COWL_OT_DR_DATA_UNION',
  'COWL_OT_DR_DATA_COMPL',
  'COWL_OT_DR_DATA_ONE_OF',
  'COWL_OT_I_ANONYMOUS',
  'COWL_OT_I_NAMED',
  'COWL_OT_OPE_OBJ_PROP',
  'COWL_OT_OPE_INV_OBJ_PROP'
]
;

our $_ENUM_TYPES = [
  'RDF::Cowl::String',
  'RDF::Cowl::Vector',
  'RDF::Cowl::Table',
  'RDF::Cowl::IRI',
  'RDF::Cowl::Literal',
  'RDF::Cowl::FacetRestr',
  'RDF::Cowl::Ontology',
  'RDF::Cowl::Manager',
  'RDF::Cowl::SymTable',
  'RDF::Cowl::IStream',
  'RDF::Cowl::OStream',
  'RDF::Cowl::Annotation',
  'RDF::Cowl::AnnotProp',
  'RDF::Cowl::DeclAxiom',
  'RDF::Cowl::DatatypeDefAxiom',
  'RDF::Cowl::SubClsAxiom',
  'RDF::Cowl::NAryClsAxiom',
  'RDF::Cowl::NAryClsAxiom',
  'RDF::Cowl::DisjUnionAxiom',
  'RDF::Cowl::ClsAssertAxiom',
  'RDF::Cowl::NAryIndAxiom',
  'RDF::Cowl::NAryIndAxiom',
  'RDF::Cowl::ObjPropAssertAxiom',
  'RDF::Cowl::ObjPropAssertAxiom',
  'RDF::Cowl::DataPropAssertAxiom',
  'RDF::Cowl::DataPropAssertAxiom',
  'RDF::Cowl::SubObjPropAxiom',
  'RDF::Cowl::InvObjPropAxiom',
  'RDF::Cowl::NAryObjPropAxiom',
  'RDF::Cowl::NAryObjPropAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::ObjPropCharAxiom',
  'RDF::Cowl::SubDataPropAxiom',
  'RDF::Cowl::NAryDataPropAxiom',
  'RDF::Cowl::NAryDataPropAxiom',
  'RDF::Cowl::FuncDataPropAxiom',
  'RDF::Cowl::DataPropDomainAxiom',
  'RDF::Cowl::DataPropRangeAxiom',
  'RDF::Cowl::HasKeyAxiom',
  'RDF::Cowl::AnnotAssertAxiom',
  'RDF::Cowl::SubAnnotPropAxiom',
  'RDF::Cowl::AnnotPropDomainAxiom',
  'RDF::Cowl::AnnotPropRangeAxiom',
  'RDF::Cowl::Class',
  'RDF::Cowl::ObjQuant',
  'RDF::Cowl::ObjQuant',
  'RDF::Cowl::ObjCard',
  'RDF::Cowl::ObjCard',
  'RDF::Cowl::ObjCard',
  'RDF::Cowl::ObjHasValue',
  'RDF::Cowl::ObjHasSelf',
  'RDF::Cowl::DataQuant',
  'RDF::Cowl::DataQuant',
  'RDF::Cowl::DataCard',
  'RDF::Cowl::DataCard',
  'RDF::Cowl::DataCard',
  'RDF::Cowl::DataHasValue',
  'RDF::Cowl::NAryBool',
  'RDF::Cowl::NAryBool',
  'RDF::Cowl::ObjCompl',
  'RDF::Cowl::ObjOneOf',
  'RDF::Cowl::DataProp',
  'RDF::Cowl::Datatype',
  'RDF::Cowl::DatatypeRestr',
  'RDF::Cowl::NAryData',
  'RDF::Cowl::NAryData',
  'RDF::Cowl::DataCompl',
  'RDF::Cowl::DataOneOf',
  'RDF::Cowl::AnonInd',
  'RDF::Cowl::NamedInd',
  'RDF::Cowl::ObjProp',
  'RDF::Cowl::InvObjProp'
]
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Enum::ObjectType - Private class for RDF::Cowl::ObjectType

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
