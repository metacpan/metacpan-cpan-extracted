package RDF::Cowl::PrimitiveType;
# ABSTRACT: Represents the type of CowlPrimitive
$RDF::Cowl::PrimitiveType::VERSION = '1.0.0';
# CowlPrimitiveType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlPrimitiveType
# From <cowl_primitive_type.h>

my @ENUM_CODES = qw(
    COWL_PT_CLASS
    COWL_PT_OBJ_PROP
    COWL_PT_DATA_PROP
    COWL_PT_ANNOT_PROP
    COWL_PT_NAMED_IND
    COWL_PT_ANON_IND
    COWL_PT_DATATYPE
    COWL_PT_IRI
);
my @_COWL_PT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_PT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlPrimitiveType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_PT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::PrimitiveType - Represents the type of CowlPrimitive

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
