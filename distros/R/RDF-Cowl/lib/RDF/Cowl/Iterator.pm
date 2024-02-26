package RDF::Cowl::Iterator;
# ABSTRACT: Iterator API
$RDF::Cowl::Iterator::VERSION = '1.0.0';
# CowlIterator
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);
use FFI::C;
use Class::Method::Modifiers qw(around after);

my $ffi = RDF::Cowl::Lib->ffi;
FFI::C->ffi($ffi);

# (opaque, CowlAny)->bool
$ffi->type( '(opaque, opaque)->opaque', 'cowl_iterator_for_each_closure_t' );

FFI::C->struct( 'CowlIterator' => [
	# void *ctx;
	'_ctx' => 'opaque',

	# cowl_iterator_for_each_closure_t
	# bool (*for_each)(void *ctx, CowlAny *object);
	_for_each => 'opaque',
]);

around new => sub {
	my ($orig, $class, $arg) = @_;
	if( ref $arg eq 'HASH' ) {
		return $orig->($class, $arg);
	} else {
		my $ret = $orig->($class);

		my $closure = $ffi->closure(sub {
			my ($ctx, $object) = @_;
			my $continue = $arg->(
				$ffi->cast( 'opaque' => 'CowlAny', $object )->_REBLESS,
			);

			$ret->_free_for_each_closure unless $continue;

			return $continue;
		});
		$closure->sticky;

		$ret->{_for_each_closure} = $closure;

		$ret->_for_each(
			$ffi->cast('cowl_iterator_for_each_closure_t' => 'opaque', $closure)
		);

		return $ret;
	}
};

sub _free_for_each_closure  {
	my ($self) = @_;
	if(exists $self->{_for_each_closure} && defined $self->{_for_each_closure}) {
		$self->{_for_each_closure}->unstick;
		delete $self->{_for_each_closure};
	}
}

after DESTROY => sub {
	my ($self) = @_;
	return unless $self;
	$self->_free_for_each_closure;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Iterator - Iterator API

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
