package PayProp::API::Public::Client::Request::Entity::Payment;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;

use PayProp::API::Public::Client::Response::Entity::Payment;


has '+url' => (
	default => sub {
		my ( $self ) = @_;
		return $self->abs_domain . '/api/agency/' . $self->api_version . '/entity/payment';
	},
);

sub list_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};
	my $path_params = $args->{path_params};

	$self->ordered_path_params([qw/ external_id /]);

	return $self
		->api_request_p({
			params => $params,
			path_params => $path_params,
			handle_response_cb => sub { $self->_get_payment( @_ ) },
		})
	;
}

sub create_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $content = $args->{content};

	return $self
		->api_request_p({
			method => 'POST',
			content => { json => $content },
			handle_response_cb => sub { $self->_get_payment( @_ ) },
		})
	;
}

sub update_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};
	my $content = $args->{content};
	my $path_params = $args->{path_params};

	$self->ordered_path_params([qw/ external_id /]);

	return $self
		->api_request_p({
			method => 'PUT',
			params => $params,
			path_params => $path_params,
			content => { json => $content },
			handle_response_cb => sub { $self->_get_payment( @_ ) },
		})
	;
}

sub _get_payment {
	my ( $self, $response_json ) = @_;

	my $Payment = PayProp::API::Public::Client::Response::Entity::Payment->new(
		id                    => $response_json->{id},
		tax                   => $response_json->{tax},
		amount                => $response_json->{amount},
		enabled               => $response_json->{enabled},
		has_tax               => $response_json->{has_tax},
		end_date              => $response_json->{end_date},
		frequency             => $response_json->{frequency},
		reference             => $response_json->{reference},
		tenant_id             => $response_json->{tenant_id},
		tax_amount            => $response_json->{tax_amount},
		start_date            => $response_json->{start_date},
		percentage            => $response_json->{percentage},
		payment_day           => $response_json->{payment_day},
		customer_id           => $response_json->{customer_id},
		description           => $response_json->{description},
		property_id           => $response_json->{property_id},
		category_id           => $response_json->{category_id},
		use_money_from        => $response_json->{use_money_from},
		beneficiary_id        => $response_json->{beneficiary_id},
		beneficiary_type      => $response_json->{beneficiary_type},
		global_beneficiary    => $response_json->{global_beneficiary},
		no_commission_amount  => $response_json->{no_commission_amount},
		maintenance_ticket_id => $response_json->{maintenance_ticket_id},
	);

	return $Payment;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Entity::Payment - Payment entity module.

=head1 SYNOPSIS

	my $Payment = PayProp::API::Public::Client::Request::Entity::Payment->new(
		domain => 'API_DOMAIN.com',                                         # Required: API domain.
		authorization => C<PayProp::API::Public::Client::Authorization::*>, # Required: Instance of an authorization module.
	);

=head1 DESCRIPTION

Implementation for creating, retrieving and updating (CRU) payment entity results via API.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 METHODS

=head2 list_p(\%args)

Issues a C<HTTP GET> request to PayProp API C</entity/payment> endpoint. It takes an optional C<HASHREF> of parameters.

See L</"QUERY PARAMETERS"> for a list of expected parameters.

	$Payment
		->list_p({ params => {...}, path_params => {...} })
		->then( sub {
			my ( $ResponsePayment ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Payment> on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 create_p(\%args)

Issues a C<HTTP POST> request to PayProp API C</entity/payment> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields.

	$Payment
		->create_p({ content => {...} })
		->then( sub {
			my ( $ResponsePayment ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Payment> on success or L<PayProp::API::Public::Client::Exception::Response> on error.


=head2 update_p(\%args)

Issues a C<HTTP PUT> request to PayProp API C</entity/payment> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields, L</"QUERY PARAMETERS"> and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Payment
		->update_p({ params => {...}, path_params => {...}, content => {...} })
		->then( sub {
			my ( $ResponsePayment ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Payment> on success or L<PayProp::API::Public::Client::Exception::Response> on error.


=head1 REQUEST BODY FIELDS

=head2 amount

B<number>
Payment amount. C<required>

=head2 category_id

B<string> C<[10..32] characters /^[a-zA-Z0-9]+$/>
Payment category external ID. C<required>

=head2 customer_id

B<string> C<[1..50] characters /^[a-zA-Z0-9]+$/>
The customer ID is a unique, case-sensitive value per API consumer. The value can be used to retrieve and update the entity. Providing C<null> on update will remove the customer ID associated with the entity. Please note that currently, this functionality is marked as experimental; we strongly recommend keeping track of PayProp entity C<external_id> along with your C<customer_id>.

=head2 description

B<string> C<E<lt>= 255 characters>
Payment description.

=head2 end_date

B<date>
Payment end date.

=head2 frequency

B<string>
Enum: C<"O"> C<"W"> C<"2W"> C<"4W"> C<"M"> C<"2M"> C<"Q"> C<"6M"> C<"A">
Payment frequency. C<required>

=head2 has_payment_period

B<boolean>
Available for reoccurring payments

=head2 has_tax

B<boolean>

=head2 is_direct_debit

B<boolean>

=head2 payment_day

B<number>
C<[1..31]> C<required>

=head2 property_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of payment property. C<required>

=head2 start_date

B<date>
Payment start date.

=head2 tenant_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of payment tenant. C<required>

=head1 QUERY PARAMETERS

=head2 is_customer_id

B<boolean>
Lookup entity based on given customer ID by overriding route C<external_id>.

=head1 PATH PARAMETERS

=head2 external_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of payment. C<required> for L</"list_p(\%args)"> and L</"update_p(\%args)">.

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
