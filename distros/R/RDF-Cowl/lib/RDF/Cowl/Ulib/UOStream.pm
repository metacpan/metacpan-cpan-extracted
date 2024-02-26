package RDF::Cowl::Ulib::UOStream;
# ABSTRACT: Models an output stream
$RDF::Cowl::Ulib::UOStream::VERSION = '1.0.0';
# UOStream
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::C;
use Class::Method::Modifiers qw(around after);

my $ffi = RDF::Cowl::Lib->ffi;
FFI::C->ffi($ffi);

# (opaque,opaque,size_t,size_t)->ustream_ret
$ffi->type( '(opaque,opaque,size_t,size_t)->int' => 'ulib_uostream_write_closure_t' );

# (opaque)->ustream_ret
$ffi->type( '(opaque)->int' => 'ulib_uostream_flush_closure_t');

# (opaque)->ustream_ret
$ffi->type( '(opaque)->int' => 'ulib_uostream_free_closure_t' );

FFI::C->struct( 'UOStream' => [
	# Stream state.
	'_state' => 'ustream_ret',

	# Bytes written since the last `flush` call.
	_written_bytes => 'size_t',

	# Stream context, can be anything.
	_ctx => 'opaque',

	# ulib_uostream_write_closure_t
	# ustream_ret (*write)(void *ctx, void const *buf, size_t count, size_t *written);
	_write => 'opaque',

	# (opaque,size_t,string,...)->ustream_ret
	# ustream_ret (*writef)(void *ctx, size_t *written, char const *format, va_list args);
	_writef => 'opaque',

	# ulib_uostream_flush_closure_t
	# ustream_ret (*flush)(void *ctx);
	_flush => 'opaque',

	# ulib_uostream_free_closure_t
	# ustream_ret (*free)(void *ctx);
	'_free' => 'opaque',
]);

# TODO around new

require RDF::Cowl::Lib::Gen::Class::UOStream unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Ulib::UOStream - Models an output stream

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::UOStream>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
