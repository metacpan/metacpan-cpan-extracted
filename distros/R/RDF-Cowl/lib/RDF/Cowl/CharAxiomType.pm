package RDF::Cowl::CharAxiomType;
# ABSTRACT: Represents the type of CowlObjPropCharAxiom
$RDF::Cowl::CharAxiomType::VERSION = '1.0.0';
# CowlCharAxiomType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlCharAxiomType
# From <cowl_char_axiom_type.h>

my @ENUM_CODES = qw(
    COWL_CAT_FUNC
    COWL_CAT_INV_FUNC
    COWL_CAT_SYMM
    COWL_CAT_ASYMM
    COWL_CAT_TRANS
    COWL_CAT_REFL
    COWL_CAT_IRREFL
);
my @_COWL_CAT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_CAT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlCharAxiomType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_CAT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::CharAxiomType - Represents the type of CowlObjPropCharAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
