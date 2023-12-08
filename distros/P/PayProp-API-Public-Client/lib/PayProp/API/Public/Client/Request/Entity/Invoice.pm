package PayProp::API::Public::Client::Request::Entity::Invoice;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;

use PayProp::API::Public::Client::Response::Entity::Invoice;


has '+url' => (
	default => sub {
		my ( $self ) = @_;
		return $self->abs_domain . '/api/agency/' . $self->api_version . '/entity/invoice';
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
			handle_response_cb => sub { $self->_get_invoice( @_ ) },
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
			handle_response_cb => sub { $self->_get_invoice( @_ ) },
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
			handle_response_cb => sub { $self->_get_invoice( @_ ) },
		})
	;
}

sub _get_invoice {
	my ( $self, $response_json ) = @_;

	my $Invoice = PayProp::API::Public::Client::Response::Entity::Invoice->new(
		id                 => $response_json->{id},
		tax                => $response_json->{tax},
		amount             => $response_json->{amount},
		has_tax            => $response_json->{has_tax},
		end_date           => $response_json->{end_date},
		frequency          => $response_json->{frequency},
		tenant_id          => $response_json->{tenant_id},
		tax_amount         => $response_json->{tax_amount},
		start_date         => $response_json->{start_date},
		deposit_id         => $response_json->{deposit_id},
		category_id        => $response_json->{category_id},
		property_id        => $response_json->{property_id},
		payment_day        => $response_json->{payment_day},
		customer_id        => $response_json->{customer_id},
		description        => $response_json->{description},
		is_direct_debit    => $response_json->{is_direct_debit},
		has_invoice_period => $response_json->{has_invoice_period},
	);

	return $Invoice;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Entity::Invoice - Invoice entity module.

=head1 SYNOPSIS

	my $Invoice = PayProp::API::Public::Client::Request::Entity::Invoice->new(
		domain => 'API_DOMAIN.com',                                         # Required: API domain.
		authorization => C<PayProp::API::Public::Client::Authorization::*>, # Required: Instance of an authorization module.
	);

=head1 DESCRIPTION

Implementation for creating, retrieving and updating (CRU) invoice entity results via API.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 METHODS

=head2 list_p(\%args)

Issues a C<HTTP GET> request to PayProp API C</entity/invoice> endpoint. It takes an optional C<HASHREF> of query and path parameters.

See L</"QUERY PARAMETERS"> and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Invoice
		->list_p({ params => {...}, path_params => {...} })
		->then( sub {
			my ( $ResponseInvoice ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Invoice> on success or L<PayProp::API::Public::Client::Exception::Response> on error.


=head2 create_p(\%args)

Issues a C<HTTP POST> request to PayProp API C</entity/invoice> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields.

	$Invoice
		->create_p({ content => {...} })
		->then( sub {
			my ( $ResponseInvoice ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Invoice> on success or L<PayProp::API::Public::Client::Exception::Response> on error.


=head2 update_p(\%args)

Issues a C<HTTP PUT> request to PayProp API C</entity/invoice> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields, L</"QUERY PARAMETERS"> and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Invoice
		->update_p({ params => {...}, path_params => {...}, content => {...} })
		->then( sub {
			my ( $ResponseInvoice ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Entity::Invoice> on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head1 REQUEST BODY FIELDS

=head2 amount

B<number>
Invoice amount. C<required>

=head2 category_id

B<string> C<[10..32] characters /^[a-zA-Z0-9]+$/>
Invoice category external ID. C<required>

=head2 customer_id

B<string> C<[1..50] characters /^[a-zA-Z0-9]+$/>
The customer ID is a unique, case-sensitive value per API consumer. The value can be used to retrieve and update the entity. Providing C<null> on update will remove the customer ID associated with the entity. Please note that currently, this functionality is marked as experimental; we strongly recommend keeping track of PayProp entity C<external_id> along with your C<customer_id>.

=head2 description

B<string> C<E<lt>= 255 characters>
Invoice description.

=head2 end_date

B<date>
Invoice end date.

=head2 frequency

B<string>
Enum: C<"O"> C<"W"> C<"2W"> C<"4W"> C<"M"> C<"2M"> C<"Q"> C<"6M"> C<"A">
Invoice frequency. C<required>

=head2 has_invoice_period

B<boolean>
Available for reoccurring invoices

=head2 has_tax

B<boolean>

=head2 is_direct_debit

B<boolean>

=head2 payment_day

B<number>
C<[1..31]> C<required>

=head2 property_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of invoice property. C<required>

=head2 start_date

B<date>
Invoice start date.

=head2 tenant_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of invoice tenant. C<required>

=head1 QUERY PARAMETERS

=head2 is_customer_id

B<boolean>
Lookup entity based on given customer ID by overriding route C<external_id>.

=head1 PATH PARAMETERS

=head2 external_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of invoice. C<required> for L</"list_p(\%arsgs)"> and L</"update_p(\%args)">.

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
