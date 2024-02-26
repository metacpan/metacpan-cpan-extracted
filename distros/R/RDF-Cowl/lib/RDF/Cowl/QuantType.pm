package RDF::Cowl::QuantType;
# ABSTRACT: Represents the type of CowlObjQuant and CowlDataQuant
$RDF::Cowl::QuantType::VERSION = '1.0.0';
# CowlQuantType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlQuantType
# From <cowl_quant_type.h>

my @ENUM_CODES = qw(
    COWL_QT_SOME
    COWL_QT_ALL
);
my @_COWL_QT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_QT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlQuantType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_QT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::QuantType - Represents the type of CowlObjQuant and CowlDataQuant

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
