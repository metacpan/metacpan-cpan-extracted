package RDF::Cowl::DataRangeType;
# ABSTRACT: Represents the type of CowlDataRange
$RDF::Cowl::DataRangeType::VERSION = '1.0.0';
# CowlDataRangeType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlDataRangeType
# From <cowl_data_range_type.h>

my @ENUM_CODES = qw(
    COWL_DRT_DATATYPE
    COWL_DRT_DATATYPE_RESTR
    COWL_DRT_DATA_INTERSECT
    COWL_DRT_DATA_UNION
    COWL_DRT_DATA_COMPL
    COWL_DRT_DATA_ONE_OF
);
my @_COWL_DRT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_DRT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlDataRangeType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_DRT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::DataRangeType - Represents the type of CowlDataRange

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
