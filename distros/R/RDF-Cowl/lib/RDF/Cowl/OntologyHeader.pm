package RDF::Cowl::OntologyHeader;
# ABSTRACT: Models an ontology header
$RDF::Cowl::OntologyHeader::VERSION = '1.0.0';
# CowlOntologyHeader
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

$ffi->type( "char[@{[ $ffi->sizeof('CowlOntologyId') ]}]", 'CowlOntologyId_record',  );

record_layout_1($ffi,
	"CowlOntologyId_record"
	               => '_id',          # CowlOntologyId
	opaque         => '_imports',     # UVec(CowlObjectPtr) const *
	opaque         => '_annotations', # UVec(CowlObjectPtr) const *
);
$ffi->type('record(RDF::Cowl::OntologyHeader)', 'CowlOntologyHeader');

around new => sub {
	my $orig  = shift;
	my $class = shift;
	my $ret = $orig->($class);

	state $signature = signature (
		named => [
			id          => Optional[CowlOntologyId],
			imports     => Optional[UVec_CowlObjectPtr],
			annotations => Optional[UVec_CowlObjectPtr],
		],
	);

	my ( $args ) = $signature->(@_);

	$ret->_id( $ffi->cast( 'string' => 'CowlOntologyId_record', ${ $args->id } ) )
		if $args->has_id;

	$ret->_imports( $ffi->cast( 'UVec_CowlObjectPtr' => 'opaque', $args->imports ) )
		if $args->has_imports;

	$ret->_annotations( $ffi->cast( 'UVec_CowlObjectPtr' => 'opaque', $args->annotations ) )
		if $args->has_annotations;

	$ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::OntologyHeader - Models an ontology header

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
