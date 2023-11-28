package PayProp::API::Public::Client::Request::Export::Tenants;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;

use PayProp::API::Public::Client::Response::Export::Tenant;
use PayProp::API::Public::Client::Response::Export::Tenant::Address;
use PayProp::API::Public::Client::Response::Export::Tenant::Property;


has '+url' => (
	default => sub {
		my ( $self ) = @_;
		return $self->abs_domain . '/api/agency/' . $self->api_version . '/export/tenants';
	},
);


sub list_p {
	my ( $self, $params ) = @_;

	return $self
		->api_request_p({
			params => $params,
			handle_response_cb => sub { $self->_get_tenants( @_ ) },
		})
	;
}

sub _get_tenants {
	my ( $self, $response_json ) = @_;

	my @tenants;
	for my $tenant ( @{ $response_json->{items} // [] } ) {
		my $Tenant = PayProp::API::Public::Client::Response::Export::Tenant->new(
			id                => $tenant->{id},
			status            => $tenant->{status},
			comment           => $tenant->{comment},
			reference         => $tenant->{reference},
			last_name         => $tenant->{last_name},
			first_name        => $tenant->{first_name},
			notify_sms        => $tenant->{notify_sms},
			id_reg_no         => $tenant->{id_reg_no},
			id_type_id        => $tenant->{id_type_id},
			vat_number        => $tenant->{vat_number},
			customer_id       => $tenant->{customer_id},
			notify_email      => $tenant->{notify_email},
			email_address     => $tenant->{email_address},
			display_name      => $tenant->{display_name},
			mobile_number     => $tenant->{mobile_number},
			id_reg_number     => $tenant->{id_reg_number},
			business_name     => $tenant->{business_name},
			date_of_birth     => $tenant->{date_of_birth},
			email_cc_address  => $tenant->{email_cc_address},
			invoice_lead_days => $tenant->{invoice_lead_days},

			address => $self->_build_address( $tenant->{address} ),
			properties => $self->_build_properties( $tenant->{properties} ),
		);

		push( @tenants, $Tenant );
	}

	return \@tenants;
}

sub _build_properties {
	my ( $self, $properties_ref ) = @_;

	return [] unless @{ $properties_ref // [] };

	my @properties;

	foreach my $property ( $properties_ref->@* ) {

		my $Property = PayProp::API::Public::Client::Response::Export::Tenant::Property->new(
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

	my $Address = PayProp::API::Public::Client::Response::Export::Tenant::Address->new(
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

sub _query_params {
	my ( $self ) = @_;

	return [
		qw/
			rows
			page
			search_by
			external_id
			property_id
			is_archived
			customer_id
			search_value
			customer_reference
			modified_from_time
			modified_from_timezone
		/
	];
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Export::Tenants - Tenant export module.

=head1 SYNOPSIS

	my $Export = $Client->export;
	my $tenants_export = $Export->tenants;

	$tenants_export
		->list_p({...})
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head1 DESCRIPTION

Implementation for retrieving tenant export results via API.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 ATTRIBUTES

C<PayProp::API::Public::Client::Request::Export::Tenants> implements the following attributes.

=head2 url

An abstraction of the API endpoint receiving the request(s). It is dependant on the API_DOMAIN.com given.

=head1 METHODS

=head2 list_p(\%query_params)

Issues a C<HTTP GET> request to PayProp API C</export/tenants> endpoint. It takes an optional C<HASHREF> of query parameters.

See L</"QUERY PARAMETERS"> for a list of available parameters.


=head1 QUERY PARAMETERS

=head2 rows

B<integer>
Restrict rows returned.

	$tenants_export
		->list_p({ rows => 1 })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 page

B<integer>
Return given page number.

	$tenants_export
		->list_p({ page => 1 })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 search_by

B<Array of string>
Items Enum: C<business_name>, C<first_name>, C<last_name>, C<email_address>

To be used with L</"search_value">.

	$tenants_export
		->list_p(
			{
				search_by => ['first_name', 'business_name'],
				search_value => 'Mike',
			}
		)
		-->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 search_value

B<string> C<[3..50] characters>
To be used with L</"search_by">.

	$tenants_export
		->list_p(
			{
				search_by => [...],
				search_value => 'Mike',
			}
		)
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 external_id

B<string> C<E<lt>= 32 characters>
External ID of tenant.

	$tenants_export
		->list_p({ external_id => 'ABCD1234' })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 property_id

B<string> C<E<lt>= 50 characters>
External ID of property.

	$tenants_export
		->list_p({ property_id => 'ABCD1234' })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 is_archived

B<boolean>
Return only tenants that have been archived. Defaults to C<false>.

	$tenants_export
		->list_p({ is_archived => true })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 customer_id

B<string> C<E<lt>= 50 characters>
Lookup entities based on C<customer_id>.

	$tenants_export
		->list_p({ customer_id => 'ABC123' })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

=head2 customer_reference

B<string> C<E<lt>= 50 characters>
Customer reference of tenant.

	$tenants_export
		->list_p({ customer_reference => 'ABC123' })
		->then( sub {
			my ( \@tenants ) = @_;
			...;

			See L<PayProp::API::Public::Client::Response::Export::Tenant>.
		} )
		->wait
	;

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
