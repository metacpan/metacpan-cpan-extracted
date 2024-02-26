package RDF::Cowl::ClsExpType;
# ABSTRACT: Represents the type of CowlClsExp
$RDF::Cowl::ClsExpType::VERSION = '1.0.0';
# CowlClsExpType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlClsExpType
# From <cowl_cls_exp_type.h>

my @ENUM_CODES = qw(
    COWL_CET_CLASS
    COWL_CET_OBJ_SOME
    COWL_CET_OBJ_ALL
    COWL_CET_OBJ_MIN_CARD
    COWL_CET_OBJ_MAX_CARD
    COWL_CET_OBJ_EXACT_CARD
    COWL_CET_OBJ_HAS_VALUE
    COWL_CET_OBJ_HAS_SELF
    COWL_CET_DATA_SOME
    COWL_CET_DATA_ALL
    COWL_CET_DATA_MIN_CARD
    COWL_CET_DATA_MAX_CARD
    COWL_CET_DATA_EXACT_CARD
    COWL_CET_DATA_HAS_VALUE
    COWL_CET_OBJ_INTERSECT
    COWL_CET_OBJ_UNION
    COWL_CET_OBJ_COMPL
    COWL_CET_OBJ_ONE_OF
);
my @_COWL_CET_CODE =
	map {
		[ $ENUM_CODES[$_] =~ s/^COWL_CET_//r , $_ ],
	} 0..$#ENUM_CODES;

$ffi->load_custom_type('::Enum', 'CowlClsExpType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_CET_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::ClsExpType - Represents the type of CowlClsExp

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
