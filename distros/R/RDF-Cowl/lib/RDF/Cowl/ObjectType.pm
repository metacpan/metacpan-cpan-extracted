package RDF::Cowl::ObjectType;
# ABSTRACT: Represents the type of CowlObject
$RDF::Cowl::ObjectType::VERSION = '1.0.0';
# CowlObjectType
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib;
use FFI::C;

my $ffi = RDF::Cowl::Lib->ffi;

# enum CowlObjectType
# From <cowl_object_type.h>

our ($_ENUM_CODES, $_ENUM_TYPES);

require RDF::Cowl::Lib::Gen::Enum::ObjectType unless $RDF::Cowl::no_gen;

my @_COWL_OT_CODE =
	map {
		[ $_ENUM_CODES->[$_] =~ s/^COWL_OT_//r , $_ ],
	} 0..$_ENUM_CODES->$#*;

$ffi->load_custom_type('::Enum', 'CowlObjectType',
	{ rev => 'int', package => __PACKAGE__ },
	@_COWL_OT_CODE,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::ObjectType - Represents the type of CowlObject

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
