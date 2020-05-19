##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/CountrySpec.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/country_specs/object
package Net::API::Stripe::Connect::CountrySpec;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub default_currency { shift->_set_get_scalar( 'default_currency', @_ ); }

sub supported_bank_account_currencies { shift->_set_get_hash( 'supported_bank_account_currencies', @_ ); }

sub supported_payment_currencies { shift->_set_get_array( 'supported_payment_currencies', @_ ); }

sub supported_payment_methods { shift->_set_get_array( 'supported_payment_methods', @_ ); }

sub supported_transfer_countries { shift->_set_get_array( 'supported_transfer_countries', @_ ); }

sub verification_fields { shift->_set_get_object( 'verification_fields', 'Net::API::Stripe::Connect::CountrySpec::VerificationFields', @_ ); }

1;

__END__

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::CountrySpec - A Stripe Country Spec Object

=head1 SYNOPSIS

    my $spec = $stripe->country_spec({
        default_currency => 'jpy',
        supported_bank_account_currencies => 
        {
        eur => [qw( be fr de it lu nl dk ie gr pt es at fi sw cy cz ee hu lv lt mt pl sk si bg ro hr va )],
        jpy => [qw( jp )],
        twd => [qw( tw )],
        },
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Stripe needs to collect certain pieces of information about each account created. These requirements can differ depending on the account's country. The Country Specs API makes these rules available to your integration.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::CountrySpec> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object. Represented as the ISO country code for this country.

=item B<object> string, value is "country_spec"

String representing the object’s type. Objects of the same type share the same value.

=item B<default_currency> string

The default currency for this country. This applies to both payment methods and bank accounts.

=item B<supported_bank_account_currencies> hash

Currencies that can be accepted in the specific country (for transfers).

=item B<supported_payment_currencies> array containing strings

Currencies that can be accepted in the specified country (for payments).

=item B<supported_payment_methods> array containing strings

Payment methods available in the specified country. You may need to enable some payment methods (e.g., ACH) on your account before they appear in this list. The stripe payment method refers to charging through your platform.

=item B<supported_transfer_countries> array containing strings

Countries that can accept transfers from the specified country.

=item B<verification_fields> hash

Lists the types of verification data needed to keep an account open.

This is a L<Net::API::Stripe::Connect::CountrySpec::VerificationFields> object.

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

L<https://stripe.com/docs/api/country_specs>, L<https://stripe.com/docs/connect/required-verification-information>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
