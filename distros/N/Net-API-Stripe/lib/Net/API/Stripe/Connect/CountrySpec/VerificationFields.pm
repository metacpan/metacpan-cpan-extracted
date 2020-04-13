##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/CountrySpec/VerificationFields.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::CountrySpec::VerificationFields;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub individual { shift->_set_get_object( 'individual', 'Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details', @_ ); }

sub company { shift->_set_get_object( 'company', 'Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::CountrySpec::VerificationFields - A Stripe Country Spec Verification Fields Object

=head1 SYNOPSIS

    my $check = $stripe->country_spec->verification_fields({
        individual => $details_object,
        company => $details_object,
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Lists the types of verification data needed to keep an account open.

This is instantiated by method B<verification_fields> from module L<Net::API::Stripe::Connect::CountrySpec>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::CountrySpec::VerificationFields> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<company> hash

Verification types for company account.

This is a L<Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details> object.

=item B<individual> hash

Verification types for individual account.

This is a L<Net::API::Stripe::Connect::CountrySpec::VerificationFields::Details> object.

=back

=head1 API SAMPLE

	{
	  "id": "US",
	  "object": "country_spec",
	  "default_currency": "usd",
	  "supported_bank_account_currencies": {
		"usd": [
		  "US"
		]
	  },
	  "supported_payment_currencies": [
		"usd",
		"aed",
		"afn",
		"..."
	  ],
	  "supported_payment_methods": [
		"ach",
		"card",
		"stripe"
	  ],
	  "supported_transfer_countries": [
		"US"
	  ],
	  "verification_fields": {
		"company": {
		  "additional": [
			"relationship.representative"
		  ],
		  "minimum": [
			"business_profile.mcc",
			"business_profile.url",
			"business_type",
			"company.address.city",
			"company.address.line1",
			"company.address.postal_code",
			"company.address.state",
			"company.name",
			"company.phone",
			"company.tax_id",
			"external_account",
			"relationship.owner",
			"relationship.representative",
			"tos_acceptance.date",
			"tos_acceptance.ip"
		  ]
		},
		"individual": {
		  "additional": [
			"individual.id_number"
		  ],
		  "minimum": [
			"business_profile.mcc",
			"business_profile.url",
			"business_type",
			"external_account",
			"individual.address.city",
			"individual.address.line1",
			"individual.address.postal_code",
			"individual.address.state",
			"individual.dob.day",
			"individual.dob.month",
			"individual.dob.year",
			"individual.email",
			"individual.first_name",
			"individual.last_name",
			"individual.phone",
			"individual.ssn_last_4",
			"tos_acceptance.date",
			"tos_acceptance.ip"
		  ]
		}
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/country_specs/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
