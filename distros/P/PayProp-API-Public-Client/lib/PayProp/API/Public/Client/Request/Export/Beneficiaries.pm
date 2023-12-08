package PayProp::API::Public::Client::Request::Export::Beneficiaries;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;

use PayProp::API::Public::Client::Response::Export::Beneficiary;
use PayProp::API::Public::Client::Response::Export::Beneficiary::Address;
use PayProp::API::Public::Client::Response::Export::Beneficiary::Property;


has '+url' => (
	default => sub {
		my ( $self ) = @_;
		return $self->abs_domain . '/api/agency/' . $self->api_version . '/export/beneficiaries';
	},
);


sub list_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};

	return $self
		->api_request_p({
			params => $params,
			handle_response_cb => sub { $self->_get_beneficiaries( @_ ) },
		})
	;
}

sub _get_beneficiaries {
	my ( $self, $response_json ) = @_;

	my @beneficiaries;
	for my $beneficiary ( @{ $response_json->{items} // [] } ) {
		my $Beneficiary = PayProp::API::Public::Client::Response::Export::Beneficiary->new(
			id                 => $beneficiary->{id},
			comment            => $beneficiary->{comment},
			is_owner           => $beneficiary->{is_owner},
			owner_app          => $beneficiary->{owner_app},
			last_name          => $beneficiary->{last_name},
			first_name         => $beneficiary->{first_name},
			notify_sms         => $beneficiary->{notify_sms},
			id_type_id         => $beneficiary->{id_type_id},
			vat_number         => $beneficiary->{vat_number},
			customer_id        => $beneficiary->{customer_id},
			notify_email       => $beneficiary->{notify_email},
			international      => $beneficiary->{international},
			email_address      => $beneficiary->{email_address},
			mobile_number      => $beneficiary->{mobile_number},
			id_reg_number      => $beneficiary->{id_reg_number},
			business_name      => $beneficiary->{business_name},
			is_active_owner    => $beneficiary->{is_active_owner},
			email_cc_address   => $beneficiary->{email_cc_address},
			customer_reference => $beneficiary->{customer_reference},

			properties => $self->_build_properties( $beneficiary->{properties} ),
			billing_address => $self->_build_address( $beneficiary->{billing_address} ),
		);

		push( @beneficiaries, $Beneficiary );
	}

	return \@beneficiaries;
}

sub _build_properties {
	my ( $self, $properties_ref ) = @_;

	return [] unless @{ $properties_ref // [] };

	my @properties;

	foreach my $property ( $properties_ref->@* ) {
		my $Property = PayProp::API::Public::Client::Response::Export::Beneficiary::Property->new(
			id => $property->{id},
			balance => $property->{balance},
			comment => $property->{comment},
			listed_from => $property->{listed_from},
			listed_until => $property->{listed_until},
			property_name => $property->{property_name},
			allow_payments => $property->{allow_payments},
			account_balance => $property->{account_balance},
			approval_required => $property->{approval_required},
			responsible_agent => $property->{responsible_agent},
			customer_reference => $property->{customer_reference},
			hold_all_owner_funds => $property->{hold_all_owner_funds},
			last_processing_info => $property->{last_processing_info},
			property_account_minimum_balance => $property->{property_account_minimum_balance},

			address => $self->_build_address( $property->{address} ),
		);

		push( @properties, $Property );
	}

	return \@properties;
}

sub _build_address {
	my ( $self, $addres_ref ) = @_;

	return undef unless %{ $addres_ref // {} };

	my $Address = PayProp::API::Public::Client::Response::Export::Beneficiary::Address->new(
		id           => $addres_ref->{id},
		fax          => $addres_ref->{fax},
		city         => $addres_ref->{city},
		email        => $addres_ref->{email},
		phone        => $addres_ref->{phone},
		state        => $addres_ref->{state},
		created      => $addres_ref->{created},
		zip_code     => $addres_ref->{zip_code},
		modified     => $addres_ref->{modified},
		latitude     => $addres_ref->{latitude},
		longitude    => $addres_ref->{longitude},
		third_line   => $addres_ref->{third_line},
		first_line   => $addres_ref->{first_line},
		second_line  => $addres_ref->{second_line},
		country_code => $addres_ref->{country_code},
	);

	return $Address;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Export::Beneficiaries - Beneficiary export module.

=head1 SYNOPSIS

	my $Export = $Client->export;
	my $beneficiaries_export = $Export->beneficiaries;

	$beneficiaries_export
		->list_p({...})
		->then( sub {
			my ( $beneficiaries ) = @_;
			...;
		} )
		->wait
	;

=head1 DESCRIPTION

Implementation for retrieving beneficiary export results via API.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 ATTRIBUTES

C<PayProp::API::Public::Client::Request::Export::Beneficiaries> implements the following attributes.

=head2 url

An abstraction of the API endpoint receiving the request(s). It is dependant on the API_DOMAIN.com given.

=head1 METHODS

=head2 list_p(\%args)

Issues a C<HTTP GET> request to PayProp API C</export/beneficiaries> endpoint. It takes an optional hashref of query parameters.
See L</"QUERY PARAMETERS"> for a list of available parameters.

	$beneficiaries_export
		->list_p({ params => {...} })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.


=head1 QUERY PARAMETERS

=head2 rows

B<integer>
Restrict rows returned.

	$beneficiaries_export
		->list_p({ params => { rows => 1 } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 page

B<integer>
Return given page number.

	$beneficiaries_export
		->list_p({ params => { page => 1 } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 owners

B<boolean>
Return only Beneficiaries that are owners.

	$beneficiaries_export
		->list_p({ params => { owners => true } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 search_by

B<Array of string>
Items Enum: C<business_name>, C<first_name>, C<last_name>, C<email_address>

To be used with L</"search_value">.

	$beneficiaries_export
		->list_p(
			{
				params => {
					search_value => 'Mike',
					search_by => ['first_name', 'business_name'],
				},
			}
		)
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 search_value

B<string> C<[3..50] characters>
To be used with L</"search_by">.

	$beneficiaries_export
		->list_p(
			{
				params => {
					search_by => [...],
					search_value => 'Mike',
				},
			}
		)
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 external_id

B<string> C<E<lt>= 32 characters>
External ID of beneficiary.

	$beneficiaries_export
		->list_p({ params => { external_id => 'ABCD1234' } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 bank_account_number

B<string> C<E<lt>= 32 characters /^[a-zA-Z0-9]+$/>
Filter beneficiaries by bank account number.

	$beneficiaries_export
		->list_p({ params => { bank_account_number => 'ab123' } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 bank_branch_code

B<string> C<E<lt>= 32 characters /^[a-zA-Z0-9]+$/>
Filter beneficiaries by bank branch code.

	$beneficiaries_export
		->list_p({ params => { bank_branch_code => 'ab123' } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 is_archived

B<boolean>
Return only beneficiaries that have been archived. Defaults to C<false>.

	$beneficiaries_export
		->list_p({ params => { is_archived => true } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 customer_id

B<string> C<E<lt>= 50 characters>
Lookup entities based on C<customer_id>.

	$beneficiaries_export
		->list_p({ params => { customer_id => 'ABC123' } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 customer_reference

B<string> C<E<lt>= 50 characters>
Customer reference of beneficiary.

	$beneficiaries_export
		->list_p({ params => { customer_reference => 'ABC123' } })
		->then( sub {
			my ( \@beneficiaries ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Export::Beneficiary> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

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