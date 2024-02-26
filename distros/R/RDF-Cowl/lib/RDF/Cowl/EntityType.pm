package RDF::Cowl::EntityType;
# ABSTRACT: Represents the type of CowlEntity
$RDF::Cowl::EntityType::VERSION = '1.0.0';
# CowlEntityType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlEntityType
# From <cowl_entity_type.h>

my @ENUM_CODES = qw(
    COWL_ET_CLASS
    COWL_ET_OBJ_PROP
    COWL_ET_DATA_PROP
    COWL_ET_ANNOT_PROP
    COWL_ET_NAMED_IND
    COWL_ET_DATATYPE
);
my @_COWL_ET_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_ET_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlEntityType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_ET_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::EntityType - Represents the type of CowlEntity

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
