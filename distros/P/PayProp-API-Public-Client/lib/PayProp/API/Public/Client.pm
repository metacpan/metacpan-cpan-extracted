package PayProp::API::Public::Client;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::Attribute::UA /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Authorization /;

# ABSTRACT: PayProp API Public Client
our $VERSION = '0.02';

has export => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Export',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Export;
		return PayProp::API::Public::Client::Request::Export->new(
			ua => $self->ua,
			domain => $self->domain,
			scheme => $self->scheme,
			authorization => $self->authorization,
		);
	}
);

has entity => (
	is => 'ro',
	isa => 'PayProp::API::Public::Client::Request::Entity',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;

		require PayProp::API::Public::Client::Request::Entity;
		return PayProp::API::Public::Client::Request::Entity->new(
			ua => $self->ua,
			domain => $self->domain,
			scheme => $self->scheme,
			authorization => $self->authorization,
		);
	}
);

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

	PayProp::API::Public::Client - PayProp API client.

=head1 SYNOPSIS

=head2 APIkey

	use PayProp::API::Public::Client;
	use PayProp::API::Public::Client::Authorization::APIKey;

	my $Client = PayProp::API::Public::Client->new(
		scheme => 'https',
		domain => 'https://staging-api.payprop.com', # relevant PayProp API domain

		authorization => PayProp::API::Public::Client::Authorization::APIKey->new(
			token => 'API_KEY_HERE'
		),
	);

	# export beneficiaries example
	my $export = $Client->export;
	my $beneficiaries_export = $export->beneficiaries;

	$beneficiaries_export
		->list_p
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Beneficiary>
		} )
		->wait
	;

=head2 OAuth v2.0 Client (access token)

	use PayProp::API::Public::Client;
	use PayProp::API::Public::Client::Authorization::ClientCredentials;
	use PayProp::API::Public::Client::Authorization::Storage::Memcached;

	my $Client = PayProp::API::Public::Client->new(
		scheme => 'https',
		domain => 'API_DOMAIN.com',                                                        # relevant PayProp API domain

		authorization => PayProp::API::Public::Client::Authorization::ClientCredentials->new(
			scheme => 'https',
			domain => 'API_DOMAIN.com',                                                     # use relevant PayProp API domain

			client => 'YourPayPropClientID',
			secret => 'your-payprop-oauth2-client-id-secret',
			application_user_id => '123',

			storage => PayProp::API::Public::Client::Authorization::Storage::Memcached->new(
				servers => [ qw/ memcached:11211 / ],                                       # Required: List of memcached servers.
				encryption_secret => 'your-optional-encryption-key',
				throw_on_storage_unavailable => 1,
			),
		),
	);

	# export beneficiaries example
	my $Export = $Client->export;
	my $beneficiaries_export = $Export->beneficiaries;

	$beneficiaries_export
		->list_p
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Beneficiary>
		} )
		->wait
	;


=head1 DESCRIPTION

	The PayProp API Public Module is a standalone module that will allow you to interact with the PayProp API,
	through a normalised interface. This interface abstracts authentication methods, request and response building and more.

	This module B<should> be used to access various API requests as defined in C<PayProp::API::Public::Client::Request::*>.

=head1 ATTRIBUTES

	C<PayProp::API::Public::Client> implements the following attributes.

=head2 export

	my $Export = $Client->export;
	my $beneficiaries_export = $Export->beneficiaries;

	See L<PayProp::API::Public::Client::Request::Export> for available attributes.

=head2 entity

	my $Entity = $Client->entity;
	my $payment_entity = $Entity->payment;

	See L<PayProp::API::Public::Client::Request::Entity> for available attributes.

=head1 METHODS


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


