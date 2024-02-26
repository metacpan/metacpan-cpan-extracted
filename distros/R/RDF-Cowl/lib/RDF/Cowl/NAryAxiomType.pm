package RDF::Cowl::NAryAxiomType;
# ABSTRACT: Represents the type of CowlNAryClsAxiom, CowlNAryObjPropAxiom, CowlNAryDataPropAxiom and CowlNAryIndAxiom
$RDF::Cowl::NAryAxiomType::VERSION = '1.0.0';
# CowlNAryAxiomType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlNAryAxiomType
# From <cowl_nary_axiom_type.h>

my @ENUM_CODES = qw(
    COWL_NAT_EQUIV
    COWL_NAT_DISJ
);
my @_COWL_NAT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_NAT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlNAryAxiomType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_NAT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::NAryAxiomType - Represents the type of CowlNAryClsAxiom, CowlNAryObjPropAxiom, CowlNAryDataPropAxiom and CowlNAryIndAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
