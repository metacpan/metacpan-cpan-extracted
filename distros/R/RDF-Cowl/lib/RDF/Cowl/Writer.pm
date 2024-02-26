package RDF::Cowl::Writer;
# ABSTRACT: Defines a writer
$RDF::Cowl::Writer::VERSION = '1.0.0';
# CowlWriter
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;

my $ffi = RDF::Cowl::Lib->ffi;
record_layout_1($ffi,
#typedef struct CowlWriter {
	# char const *name;
	'string' => 'name',

	# cowl_ret (*write_ontology)(UOStream *stream, CowlOntology *ontology);
	opaque => 'write_ontology',

	# cowl_ret (*write)(UOStream *stream, CowlAny *object);
	opaque => 'write',

	# CowlStreamWriter stream;
	"char[@{[ $ffi->sizeof('CowlStreamWriter') ]}]"
	               => 'stream',
);
$ffi->type('record(RDF::Cowl::Writer)', 'CowlWriter');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Writer - Defines a writer

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
