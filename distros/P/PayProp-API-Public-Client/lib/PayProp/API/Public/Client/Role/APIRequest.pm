package PayProp::API::Public::Client::Role::APIRequest;

use strict;
use warnings;

use Mouse::Role;
with qw/ PayProp::API::Public::Client::Role::Request /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Domain /;
with qw/ PayProp::API::Public::Client::Role::Attribute::APIVersion /;
with qw/ PayProp::API::Public::Client::Role::Attribute::Authorization /;

use PayProp::API::Public::Client::Exception::Response;

sub api_request_p {
	my ( $self, $args ) = @_;

	$self
		->_api_request_p( $args )
		->catch( sub {
			my ( $error ) = @_;

			if ( $self->_can_retry_request( $error ) ) {
				return $self
					->authorization
					->remove_token_from_storage_p
					->then( sub { $self->_api_request_p( $args ) } )
				;
			}

			$error->rethrow;
		} )
	;
}

sub _api_request_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $headers = $args->{headers} // {};
	my $method = $args->{method} // 'GET';
	my $handle_response_cb = $args->{handle_response_cb};

	my $request_method = {
		GET => 'get_req_p',
		PUT => 'put_req_p',
		POST => 'post_req_p',
	}->{ uc( $method // '' ) }
		or die "method $method not suported for api_request_p"
	;

	die 'handle_response_cb must be CODE ref'
		if $handle_response_cb && ref $handle_response_cb ne 'CODE'
	;

	return $self
		->authorization
		->token_request_p
		->then( sub {
			my ( $token_info ) = @_;

			my ( $token, $token_type ) = @$token_info{qw/ token token_type /};

			return $self
				->$request_method({
					$args->%*,
					headers => {
						Authorization => "$token_type $token",
						$headers->%*,
					},
				})
			;
		} )
		->then( sub {
			my ( $Transaction ) = @_;

			my $Result = $Transaction->result;
			$self->_maybe_throw_response_exception( $Result );

			return $Result->json;
		} )
		->then( sub {
			my ( $response_json ) = @_;

			return (
				( $handle_response_cb ? $handle_response_cb->( $response_json ) : $response_json ),
				{
					pagination => $response_json->{pagination},
				}
			);
		} )
	;
}

sub _maybe_throw_response_exception {
	my ( $self, $Result ) = @_;

	return undef if $Result->is_success;

	my $json = $Result->json // {};
	my $errors = $json->{errors} // [ { path => '/NO_PATH', message => 'NO_ERROR_MESSAGE' } ];

	PayProp::API::Public::Client::Exception::Response->throw(
		status_code => $Result->code,
		errors => [
			map { +{ %$_{qw/ path message /} } } $errors->@*
		],
	);
}

sub _can_retry_request {
	my ( $self, $error ) = @_;

	return
		$self->authorization->has_storage
		&& $self->authorization->is_token_from_storage
		&& ref( $error ) eq 'PayProp::API::Public::Client::Exception::Response'
		&& ( $error->status_code // -1 ) == 401
	;
}

1;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Role::APIRequest - Role to encapsulate API requests.

=head1 SYNOPSIS

	package PayProp::API::Public::Client::Request::*;
	with qw/ PayProp::API::Public::Client::Role::APIRequest /;

	...;

	__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Define methods to call various API endpoints via retry flow.

=head1 METHODS

=head2 api_request_p(\%args)

Method to be called from API modules that implements retry mechanism and handles exceptions.

	my $Promise = $self->api_request_p({
		method => 'POST',
		params => { ... },
	});

Returns C<Mojo::Promise> resolving to underlying API response modules on success or C<PayProp::API::Public::Client::Exception::Response> on API error response.

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

