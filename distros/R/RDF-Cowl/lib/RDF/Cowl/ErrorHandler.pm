package RDF::Cowl::ErrorHandler;
# ABSTRACT: Provides a mechanism for error handling
$RDF::Cowl::ErrorHandler::VERSION = '1.0.0';
# CowlErrorHandler
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::Platypus::Record;
use Class::Method::Modifiers qw(around);

my $ffi = RDF::Cowl::Lib->ffi;

# (opaque, CowlError)->void
$ffi->type( '(opaque, opaque)->opaque', 'cowl_error_handler_handle_error_closure_t' );

$ffi->type( '(opaque)->void', 'cowl_error_handler_free_closure_t' );

record_layout_1($ffi,
	'opaque' => '_ctx',

	# cowl_error_handler_handle_error_closure_t
	# void (*handle_error)(void *ctx, CowlError const *error);
	'opaque' => '_handle_error',

	# cowl_error_handler_free_closure_t
	# void (*free)(void *ctx);
	'opaque' => '_free',
);
$ffi->type('record(RDF::Cowl::ErrorHandler)', 'CowlErrorHandler');

around new => sub {
	my ($orig, $class, $arg) = @_;
	if( ref $arg eq 'HASH' ) {
		return $orig->($class, $arg);
	} else {
		my $ret = $orig->($class);

		my $closure = $ffi->closure(sub {
			my ($ctx, $error) = @_;
			return $arg->(
				$ffi->cast( 'opaque' => 'CowlError', $error ),
			);
		});
		$closure->sticky;

		$ret->_handle_error(
			$ffi->cast('cowl_error_handler_free_closure_t' => 'opaque', $closure)
		);

		$ret->_free(
			$ffi->cast('cowl_error_handler_free_closure_t', 'opaque',
				$ffi->closure(\&_free_error_handler_closure))
		);

		return $ret;
	}
};

sub _free_error_handler_closure {
	my ($self) = @_;
	$self->cast('opaque' => 'cowl_error_handler_handle_error_closure_t',
		$self->_handle_error)->unstick;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::ErrorHandler - Provides a mechanism for error handling

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
