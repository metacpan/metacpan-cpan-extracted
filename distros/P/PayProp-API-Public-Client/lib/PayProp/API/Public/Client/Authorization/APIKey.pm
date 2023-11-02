package PayProp::API::Public::Client::Authorization::APIKey;

use strict;
use warnings;

use Mouse;
extends qw/ PayProp::API::Public::Client::Authorization::Base /;

use Mojo::Promise;

has token => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has '+token_type' => ( default => sub { 'APIkey' } );

sub _token_request_p {
	my ( $self ) = @_;

	return Mojo::Promise
		->new( sub {
			my ( $resolve, $reject ) = @_;

			return $resolve->({
				token => $self->token,
				token_type => $self->token_type,
			});
		} )
	;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client::Authorization::APIKey - API key authorization module.

=head1 SYNOPSIS

	use PayProp::API::Public::Client::Authorization::APIKey;

	my $APIKey = PayProp::API::Public::Client::Authorization::APIKey->new(
		token => 'YOUR_API_KEY', # Required: PayProp API key.
	);

=head1 DESCRIPTION

	API key authorization module type to be provided for C<PayProp::API::Public::Client> initialization.
	Note that C<storage_key> is not overridden in this module as it's not expected for this module to utilize storage solution;
	an exception will be thrown by default if storage is provided for C<PayProp::API::Public::Client::Authorization::APIKey> module.

=head1 ATTRIBUTES

	C<PayProp::API::Public::Client::Authorization::APIKey> implements the following attributes.

=head2 token

	API key obtained from the PayProp platform.

=head2 token_type

	API key authorization type. Default C<APIkey>

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
