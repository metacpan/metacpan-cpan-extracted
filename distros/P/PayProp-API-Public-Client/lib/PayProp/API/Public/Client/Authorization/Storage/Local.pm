package PayProp::API::Public::Client::Authorization::Storage::Local;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Storage /;

use Mojo::Promise;

has storage => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { +{} },
);

sub _ping_p {
	my ( $self ) = @_;

	return Mojo::Promise->new(
		sub {
			my( $resolve, $reject ) = @_;

			return ref( $self->storage ) eq 'HASH' ? $resolve->( 1 ) : $reject->( 0 );
		}
	);
}

sub _set_p {
	my ( $self, $key, $value ) = @_;

	return Mojo::Promise->new(
		sub {
			my( $resolve, $reject ) = @_;

			$self->storage->{ $key } = $value;

			return $resolve->( 1 );
		}
	);
}

sub _get_p {
	my ( $self, $key ) = @_;

	return Mojo::Promise->new(
		sub {
			my( $resolve, $reject ) = @_;

			return $resolve->( $self->storage->{ $key } );
		}
	);
}

sub _delete_p {
	my ( $self, $key ) = @_;

	return Mojo::Promise->new(
		sub {
			my( $resolve, $reject ) = @_;

			delete $self->storage->{ $key };

			return $resolve->( 1 );
		}
	);
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client::Authorization::Storage::Local - Local in-memory storage for tokens.

=head1 SYNOPSIS

	use PayProp::API::Public::Client::Authorization::Storage::Local;

	my $Storage = PayProp::API::Public::Client::Authorization::Storage::Local->new(
		encryption_secret => 'bleh blurp berp',
		throw_on_storage_unavailable => 1,
	);

=head1 DESCRIPTION

	Local key-value storage solution to be provided for C<PayProp::API::Public::Client::Authorization::*>.

=head1 ATTRIBUTES

	C<PayProp::API::Public::Client::Authorization::Storage::Local> implements the following attributes.

=head2 storage

	my $storage = $Storage->storage;
	my $storage_value = $storage->{<your_storage_key>};

=head1 AUTHOR

	Yanga Kandeni E<lt>yangak@cpan.orgE<gt>

	Valters Skrupskis E<lt>malishew@cpan.orgE<gt>

=head1 COPYRIGHT

	Copyright 2023- PayProp

=head1 LICENSE

	This library is free software; you can redistribute it and/or modify
	it under the same terms as Perl itself.

	If you would like to contribute documentation
	or file a bug report then please raise an issue / pull request:

	L<https://github.com/Humanstate/api-client-public-module>

=cut
