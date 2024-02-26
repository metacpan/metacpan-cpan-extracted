package RDF::Cowl::AxiomType;
# ABSTRACT: Represents the type of CowlAxiom
$RDF::Cowl::AxiomType::VERSION = '1.0.0';
# CowlAxiomType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlAxiomType
# From <cowl_axiom_type.h>

my @ENUM_CODES = qw(
    COWL_AT_DECL
    COWL_AT_DATATYPE_DEF
    COWL_AT_SUB_CLASS
    COWL_AT_EQUIV_CLASSES
    COWL_AT_DISJ_CLASSES
    COWL_AT_DISJ_UNION
    COWL_AT_CLASS_ASSERT
    COWL_AT_SAME_IND
    COWL_AT_DIFF_IND
    COWL_AT_OBJ_PROP_ASSERT
    COWL_AT_NEG_OBJ_PROP_ASSERT
    COWL_AT_DATA_PROP_ASSERT
    COWL_AT_NEG_DATA_PROP_ASSERT
    COWL_AT_SUB_OBJ_PROP
    COWL_AT_INV_OBJ_PROP
    COWL_AT_EQUIV_OBJ_PROP
    COWL_AT_DISJ_OBJ_PROP
    COWL_AT_FUNC_OBJ_PROP
    COWL_AT_INV_FUNC_OBJ_PROP
    COWL_AT_SYMM_OBJ_PROP
    COWL_AT_ASYMM_OBJ_PROP
    COWL_AT_TRANS_OBJ_PROP
    COWL_AT_REFL_OBJ_PROP
    COWL_AT_IRREFL_OBJ_PROP
    COWL_AT_OBJ_PROP_DOMAIN
    COWL_AT_OBJ_PROP_RANGE
    COWL_AT_SUB_DATA_PROP
    COWL_AT_EQUIV_DATA_PROP
    COWL_AT_DISJ_DATA_PROP
    COWL_AT_FUNC_DATA_PROP
    COWL_AT_DATA_PROP_DOMAIN
    COWL_AT_DATA_PROP_RANGE
    COWL_AT_HAS_KEY
    COWL_AT_ANNOT_ASSERT
    COWL_AT_SUB_ANNOT_PROP
    COWL_AT_ANNOT_PROP_DOMAIN
    COWL_AT_ANNOT_PROP_RANGE
);
my @_COWL_AT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_AT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlAxiomType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_AT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::AxiomType - Represents the type of CowlAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
