##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Company.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Company;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub address_kana { return( shift->_set_get_object( 'address_kana', 'Net::API::Stripe::AddressKana', @_ ) ); }

sub address_kanji { return( shift->_set_get_object( 'address_kanji', 'Net::API::Stripe::AddressKanji', @_ ) ); }

sub directors_provided { return( shift->_set_get_scalar( 'directors_provided', @_ ) ); }

sub executives_provided { return( shift->_set_get_boolean( 'executives_provided', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub name_kana { return( shift->_set_get_scalar( 'name_kana', @_ ) ); }

sub name_kanji { return( shift->_set_get_scalar( 'name_kanji', @_ ) ); }

sub owners_provided { return( shift->_set_get_scalar( 'owners_provided', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub structure { return( shift->_set_get_scalar( 'structure', @_ ) ); }

sub tax_id_provided { return( shift->_set_get_scalar( 'tax_id_provided', @_ ) ); }

sub tax_id_registrar { return( shift->_set_get_scalar( 'tax_id_registrar', @_ ) ); }

sub vat_id_provided { return( shift->_set_get_scalar( 'owners_provided', @_ ) ); }

sub verification { return( shift->_set_get_object( 'verification', 'Net::API::Stripe::Connect::Account::Verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Company - A Stripe Company Object

=head1 SYNOPSIS

    my $cie = $stripe->account->company({
        address => $stripe->address({
            line1 => '1-2-3 Kudan-Minami, Chiyoda-ku',
            line2 => 'Big Bldg 12F',
            city => 'Tokyo',
            postal_code => '123-4567',
            country => 'jp',
        }),
	   address_kana => $stripe->address({
		   line1 => 'ちよだくくだんみなみ1-2-3',
		   line2 => 'だいびる12かい',
		   city => 'とうきょうと',
		   postal_code => '123-4567',
		   country => 'jp',
	   }),
	   address_kanji => $stripe->address({
		   line1 => '千代田区九段南1-2-3',
		   line2 => '大ビル12階',
		   city => '東京都',
		   postal_code => '123-4567',
		   country => 'jp',
	   }),
	   name => 'Yamato Nadehiko, Inc',
	   name_kana => 'やまとなでひこかぶしきがいしゃ',
	   name_kanji => '大和撫子株式会社',
	   phone => '+81-(0)3-1234-5678',
	   structure => 'private_corporation',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Settings used to apply the account’s branding to email receipts, invoices, Checkout, and other products.

This is called from method B<company> in modules L<Net::API::Stripe::Connect::Account> and L<Net::API::Stripe::Issuing::Card::Holder>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Company> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<address> hash

The company’s primary address.

This is a L<Net::API::Stripe::Address> object.

=item B<address_kana> hash

The Kana variation of the company’s primary address (Japan only).

This is a L<Net::API::Stripe::Address> object.
 
=item B<address_kanji> hash

The Kanji variation of the company’s primary address (Japan only).

This is a L<Net::API::Stripe::Address> object.

=item B<directors_provided> boolean

Whether the company’s directors have been provided. This Boolean will be true if you’ve manually indicated that all directors are provided via the directors_provided parameter.

=item B<executives_provided> boolean

Whether the company’s executives have been provided. This Boolean will be true if you’ve manually indicated that all executives are provided via the executives_provided parameter, or if Stripe determined that sufficient executives were provided.

=item B<name> string

The company’s legal name.

=item B<name_kana> string

The Kana variation of the company’s legal name (Japan only).

=item B<name_kanji> string

The Kanji variation of the company’s legal name (Japan only).

=item B<owners_provided> boolean

Whether the company’s owners have been provided. This Boolean will be true if you’ve manually indicated that all owners are provided via the owners_provided parameter, or if Stripe determined that all owners were provided. Stripe determines ownership requirements using both the number of owners provided and their total percent ownership (calculated by adding the percent_ownership of each owner together).

=item B<phone> string

The company’s phone number (used for verification).

=item B<structure> string

The category identifying the legal structure of the company or legal entity. See Business structure for more details (L<https://stripe.com/docs/connect/identity-verification#business-structure>).

Possible enum values

=over 4

=item government_instrumentality

=item governmental_unit

=item incorporated_non_profit

=item multi_member_llc

=item private_corporation

=item private_partnership

=item public_corporation

=item public_partnership

=item tax_exempt_government_instrumentality

=item unincorporated_association

=item unincorporated_non_profit

=back

=item B<tax_id_provided> boolean

Whether the company’s business ID number was provided.

=item B<tax_id_registrar> string

The jurisdiction in which the tax_id is registered (Germany-based companies only).

=item B<vat_id_provided> boolean

Whether the company’s business VAT number was provided.

=item B<verification> hash

Information on the verification state of the company. This is a L<Net::API::Stripe::Connect::Account::Verification> object.

=back

=head1 API SAMPLE

	{
	  "id": "acct_fake123456789",
	  "object": "account",
	  "business_profile": {
		"mcc": null,
		"name": "My Shop, Inc",
		"product_description": "Great products shipping all over the world",
		"support_address": {
		  "city": "Tokyo",
		  "country": "JP",
		  "line1": "1-2-3 Kudan-minami, Chiyoda-ku",
		  "line2": "",
		  "postal_code": "100-0012",
		  "state": ""
		},
		"support_email": "billing@example.com",
		"support_phone": "+81312345678",
		"support_url": "",
		"url": "https://www.example.com"
	  },
	  "business_type": "company",
	  "capabilities": {
		"card_payments": "active"
	  },
	  "charges_enabled": true,
	  "country": "JP",
	  "default_currency": "jpy",
	  "details_submitted": true,
	  "email": "tech@example.com",
	  "metadata": {},
	  "payouts_enabled": true,
	  "settings": {
		"branding": {
		  "icon": "file_fake123456789",
		  "logo": null,
		  "primary_color": "#0e77ca"
		},
		"card_payments": {
		  "decline_on": {
			"avs_failure": false,
			"cvc_failure": false
		  },
		  "statement_descriptor_prefix": null
		},
		"dashboard": {
		  "display_name": "myshop-inc",
		  "timezone": "Asia/Tokyo"
		},
		"payments": {
		  "statement_descriptor": "MYSHOP, INC",
		  "statement_descriptor_kana": "ﾏｲｼｮｯﾌﾟｲﾝｸ",
		  "statement_descriptor_kanji": "マイショップインク"
		},
		"payouts": {
		  "debit_negative_balances": true,
		  "schedule": {
			"delay_days": 4,
			"interval": "weekly",
			"weekly_anchor": "thursday"
		  },
		  "statement_descriptor": null
		}
	  },
	  "type": "standard"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Stripe added the B<executives_provided> property.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/accounts/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
