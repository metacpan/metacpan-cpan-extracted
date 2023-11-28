package PayProp::API::Public::Client::Authorization::ClientCredentials;

use strict;
use warnings;

use Mouse;
extends qw/ PayProp::API::Public::Client::Authorization::Base /;
with qw/ PayProp::API::Public::Client::Role::Request /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;

use MIME::Base64 qw//;
use PayProp::API::Public::Client::Exception::Authorization;

has [ qw/ client secret application_user_id / ] => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has '+token_type' => ( default => sub { 'Bearer' } );
has '+url' => ( default => sub { shift->abs_domain . '/api/oauth/access_token' } );
has '+storage_key' => ( default => sub { join( '|', 'ClientCredentials', $_[0]->client, $_[0]->application_user_id ) } );

has _encoded_key => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	builder => '_build_encoded_key',
);

sub _token_request_p {
	my ( $self ) = @_;

	return $self
		->post_req_p({
			headers => { Authorization => 'Basic ' . $self->_encoded_key },
			params => {
				grant_type => 'client_credentials',
				application_user_id => $self->application_user_id,
			},
		})
		->then( sub {
			my ( $Transaction ) = @_;

			my $Result = $Transaction->result;

			my $json = $Result->json // {};
			my $access_token = $json->{access_token};

			PayProp::API::Public::Client::Exception::Authorization->throw(
				status_code => $Result->code,
				errors => [
					{
						code => $json->{error} // 'NO_ERROR_CODE',
						message => $json->{error_description} // 'NO_ERROR_MESSAGE',
					},
				],
			)
				unless $access_token
			;

			return {
				token => $access_token,
				token_type => $self->token_type,
			};
		} )
	;
}

sub _build_encoded_key {
	my ( $self ) = @_;

	my $encoded_key = MIME::Base64::encode_base64( $self->client . ':' . $self->secret );
	chomp $encoded_key;

	return $encoded_key;
}

sub _query_params {
	my ( $self ) = @_;

	return [qw/ grant_type application_user_id /];
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8


=head1 NAME

PayProp::API::Public::Client::Authorization::ClientCredentials - Client credentials authorization module.

=head1 SYNOPSIS

use PayProp::API::Public::Client::Authorization::ClientCredentials;

my $ClientCredentials = PayProp::API::Public::Client::Authorization::ClientCredentials->new(
	client => 'OAUTH_CLIENT',        # Required: OAuth v2.0 client.
	secret => 'OAUTH_CLIENT_SECRET', # Required: OAuth v2.0 client secret.
	domain => 'API-DOMAIN.com',      # Required: API server domain name.
	application_user_id => 123456,   # Required: Client for which to request OAuth v2.0 access token.

	scheme => 'https',          # Optional: API domain URL scheme. Default C<https>.
	storage_key => 'CACHE_KEY', # Optional: Token storage key. This *should* be unique per C<application_user_id> if overridden.
	storage => C<PayProp::API::Public::Client::Authorization::Storage::*>, # Optional: One of available storage solutions.
);

=head1 DESCRIPTION

Client credentials authorization module type to be provided for C<PayProp::API::Public::Client> initialization.

=head1 ATTRIBUTES

C<PayProp::API::Public::Client::Authorization::ClientCredentials> implements the following attributes.

=head2 client

OAuth v2.0 client.

=head2 secret

OAuth v2.0 client secret.

=head2 domain

API server domain name.

=head2 application_user_id

Client for which to request OAuth v2.0 access token.

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

