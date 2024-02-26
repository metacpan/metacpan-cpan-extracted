package RDF::Cowl::Entity;
# ABSTRACT: Represents an Entity in the OWL 2 specification
$RDF::Cowl::Entity::VERSION = '1.0.0';
# CowlEntity
use strict;
use warnings;
use parent 'RDF::Cowl::Primitive';
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

##############################
# * @note Only available if COWL_ENTITY_IDS is defined.
#
$ffi->ignore_not_found(1);

$ffi->attach( [ "cowl_entity_get_id" => "get_id" ] =>
	[
		arg "CowlAnyEntity" => "entity",
	],
	=> "ulib_uint"
);

$ffi->attach( [ "cowl_entity_with_id" => "with_id" ] =>
	[
		arg "ulib_uint" => "id",
	],
	=> "CowlAnyEntity"
);

$ffi->ignore_not_found(0);
##############################

require RDF::Cowl::Lib::Gen::Class::Entity unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Entity - Represents an Entity in the OWL 2 specification

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::Entity>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
