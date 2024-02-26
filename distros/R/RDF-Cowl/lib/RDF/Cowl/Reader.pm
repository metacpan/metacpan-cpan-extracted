package RDF::Cowl::Reader;
# ABSTRACT: Defines a reader
$RDF::Cowl::Reader::VERSION = '1.0.0';
# CowlReader
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;

my $ffi = RDF::Cowl::Lib->ffi;
record_layout_1($ffi,
	# char const *name;
	'string' => 'name',

	# cowl_ret (*read)(UIStream *istream, CowlIStream *stream);
	opaque => 'read',
);
$ffi->type('record(RDF::Cowl::Reader)', 'CowlReader');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Reader - Defines a reader

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
