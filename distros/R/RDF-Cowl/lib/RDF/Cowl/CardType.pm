package RDF::Cowl::CardType;
# ABSTRACT: Represents the type of CowlObjCard and CowlDataCard
$RDF::Cowl::CardType::VERSION = '1.0.0';
# CowlCardType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlCardType
# From <cowl_card_type.h>

my @ENUM_CODES = qw(
    COWL_CT_MIN
    COWL_CT_MAX
    COWL_CT_EXACT
);
my @_COWL_CT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_CT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlCardType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_CT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::CardType - Represents the type of CowlObjCard and CowlDataCard

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
