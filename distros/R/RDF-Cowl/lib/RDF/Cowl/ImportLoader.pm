package RDF::Cowl::ImportLoader;
# ABSTRACT: Provides a mechanism for generic handling of ontology imports
$RDF::Cowl::ImportLoader::VERSION = '1.0.0';
# CowlImportLoader
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;
use Class::Method::Modifiers qw(around after);

my $ffi = RDF::Cowl::Lib->ffi;

# (opaque, CowlIRI)->CowlOntology
$ffi->type( '(opaque, opaque)->opaque', 'cowl_import_loader_load_ontology_closure_t' );

$ffi->type( '(opaque)->void', 'cowl_import_loader_free_closure_t' );

record_layout_1($ffi,
	'opaque' => '_ctx',

	# cowl_import_loader_load_ontology_closure_t
	# CowlOntology *(*load_ontology)(void *ctx, CowlIRI *iri);
	opaque => '_load_ontology',

	# cowl_import_loader_free_closure_t
	# void (*free)(void *ctx);
	opaque => '_free',
);
$ffi->type('record(RDF::Cowl::ImportLoader)', 'CowlImportLoader');

around new => sub {
	my ($orig, $class, $arg) = @_;
	if( ref $arg eq 'HASH' ) {
		return $orig->($class, $arg);
	} else {
		my $ret = $orig->($class);

		my $closure = $ffi->closure(sub {
			my ($ctx, $iri) = @_;
			return $arg->(
				$ffi->cast( 'opaque' => 'CowlIRI', $iri )
			);
		});
		$closure->sticky;

		$ret->_load_ontology(
			$ffi->cast('cowl_import_loader_load_ontology_closure_t' => 'opaque', $closure)
		);

		$ret->_free(
			$ffi->cast('cowl_import_loader_free_closure_t', 'opaque',
				$ffi->closure(\&_free_load_ontology_closure))
		);

		return $ret;
	}
};

sub _free_load_ontology_closure {
	my ($self) = @_;
	$self->cast('opaque' => 'cowl_import_loader_load_ontology_closure_t',
		$self->_load_ontology)->unstick;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::ImportLoader - Provides a mechanism for generic handling of ontology imports

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
