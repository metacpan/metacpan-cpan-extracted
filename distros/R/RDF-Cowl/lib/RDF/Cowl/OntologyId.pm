package RDF::Cowl::OntologyId;
# ABSTRACT: An object that identifies an ontology
$RDF::Cowl::OntologyId::VERSION = '1.0.0';
# CowlOntologyId
use strict;
use warnings;
use namespace::autoclean;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Optional);
use Type::Params -sigs;
use Class::Method::Modifiers qw(around after);

use FFI::Platypus::Record;

my $ffi = RDF::Cowl::Lib->ffi;

record_layout_1($ffi,
	opaque => '_iri', # CowlIRI*
	opaque => '_version', # CowlIRI*
);
$ffi->type('record(RDF::Cowl::OntologyId)', 'CowlOntologyId');

around new => sub {
	my $orig  = shift;
	my $class = shift;
	my $ret = $orig->($class);

	state $signature = signature (
		named => [
			iri      => Optional[CowlIRI],
			version  => Optional[CowlIRI],
		],
	);

	my ( $args ) = $signature->(@_);

	$ret->_iri( $ffi->cast( 'CowlIRI' => 'opaque', $args->iri ) )
		if $args->has_iri;

	$ret->_version( $ffi->cast( 'CowlIRI' => 'opaque', $args->version ) )
		if $args->has_version;

	$ret;
};


sub iri {
	my ($self) = @_;
	return $ffi->cast('opaque', 'CowlIRI', $self->_iri )
}

sub version {
	my ($self) = @_;
	return $ffi->cast('opaque', 'CowlIRI', $self->_version )
}

require RDF::Cowl::Lib::Gen::Class::OntologyId unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::OntologyId - An object that identifies an ontology

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::OntologyId>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
