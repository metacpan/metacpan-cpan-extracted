package RDF::Cowl::NAryType;
# ABSTRACT: Represents the type of CowlNAryBool and CowlNAryData
$RDF::Cowl::NAryType::VERSION = '1.0.0';
# CowlNAryType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlNAryType
# From <cowl_nary_type.h>

my @ENUM_CODES = qw(
    COWL_NT_INTERSECT
    COWL_NT_UNION
);
my @_COWL_NT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_NT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlNAryType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_NT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::NAryType - Represents the type of CowlNAryBool and CowlNAryData

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
