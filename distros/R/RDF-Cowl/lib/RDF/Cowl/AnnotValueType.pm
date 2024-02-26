package RDF::Cowl::AnnotValueType;
# ABSTRACT: Represents the type of CowlAnnotValue
$RDF::Cowl::AnnotValueType::VERSION = '1.0.0';
# CowlAnnotValueType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlAnnotValueType
# From <cowl_annot_value_type.h>

my @ENUM_CODES = qw(
    COWL_AVT_IRI
    COWL_AVT_LITERAL
    COWL_AVT_ANON_IND
);
my @_COWL_AVT_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_AVT_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlAnnotValueType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_AVT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::AnnotValueType - Represents the type of CowlAnnotValue

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
