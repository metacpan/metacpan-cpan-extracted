package RDF::Cowl::StreamWriter;
# ABSTRACT: Defines functions that must be implemented by stream writers
$RDF::Cowl::StreamWriter::VERSION = '1.0.0';
# CowlStreamWriter
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;

my $ffi = RDF::Cowl::Lib->ffi;
record_layout_1($ffi,
	# cowl_ret (*write_header)(UOStream *stream, CowlSymTable *st, CowlOntologyHeader header);
	opaque => 'write_header',

	# cowl_ret (*write_axiom)(UOStream *stream, CowlSymTable *st, CowlAnyAxiom *axiom);
	opaque => 'write_axiom',

	# cowl_ret (*write_footer)(UOStream *stream, CowlSymTable *st);
	opaque => 'write_footer',
);
$ffi->type('record(RDF::Cowl::StreamWriter)', 'CowlStreamWriter');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::StreamWriter - Defines functions that must be implemented by stream writers

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
