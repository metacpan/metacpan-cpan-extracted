##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Business/Profile.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Business::Profile;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub mcc { return( shift->_set_get_scalar( 'mcc', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub product_description { return( shift->_set_get_scalar( 'product_description', @_ ) ); }

sub support_address { return( shift->_set_get_object( 'support_address', 'Net::API::Stripe::Address', @_ ) ); }

sub support_email { return( shift->_set_get_scalar( 'support_email', @_ ) ); }

sub support_phone { return( shift->_set_get_scalar( 'support_phone', @_ ) ); }

sub support_url { return( shift->_set_get_uri( 'support_url', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Business::Profile - A Stripe Account Business Profile Object

=head1 SYNOPSIS

    my $profile = $stripe->account->business_profile({
        name => 'Big Corp, Inc',
        product_description => 'Professional services',
        support_address => $address_object,
        support_email => 'john.doe@example.com',
        support_phone => '+81-(0)90-1234-5678',
        support_url => 'https://example.com/support',
        url => 'https://example.com',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Optional information related to the business.

This is instantiated by method B<business_profile> from module L<Net::API::Stripe::Connect::Account>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Business::Profile> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<mcc> string

The merchant category code for the account. MCCs are used to classify businesses based on the goods or services they provide.

=item B<name> string

The customer-facing business name.

=item B<product_description> string

Internal-only description of the product sold or service provided by the business. It’s used by Stripe for risk and underwriting purposes.

=item B<support_address> hash

A publicly available mailing address for sending support issues to.

This is a L<Net::API::Stripe::Address> object.

=item B<support_email> string

A publicly available email address for sending support issues to.

=item B<support_phone> string

A publicly available phone number to call with support issues.

=item B<support_url> string

A publicly available website for handling support issues.

This is a C<URI> object.

=item B<url> string

The business’s publicly available website.

This is a C<URI> object.

=back

=head1 API SAMPLE

	{
	  "id": "acct_fake123456789",
	  "object": "account",
	  "business_profile": {
		"mcc": null,
		"name": "MyShop, Inc",
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
	  "company": {
		"address_kana": {
		  "city": "ﾁﾖﾀﾞｸ",
		  "country": "JP",
		  "line1": "2-3",
		  "line2": "ﾅｼ",
		  "postal_code": null,
		  "state": null,
		  "town": "ｸﾀﾞﾝﾐﾅﾐ1"
		},
		"address_kanji": {
		  "city": "千代田区",
		  "country": "JP",
		  "line1": "",
		  "line2": "",
		  "postal_code": null,
		  "state": null,
		  "town": "九段南1-2-3"
		},
		"directors_provided": false,
		"name": "MyShop, Inc",
		"name_kana": "ｶﾌﾞｼｷｶｲｼｬﾏｲｼｮｯﾌﾟｲﾝｸ",
		"name_kanji": "株式会社マイショップインク",
		"owners_provided": true,
		"phone": null,
		"tax_id_provided": true,
		"verification": {
		  "document": {
			"back": null,
			"details": null,
			"details_code": null,
			"front": null
		  }
		}
	  },
	  "country": "JP",
	  "created": 1484973659,
	  "default_currency": "jpy",
	  "details_submitted": true,
	  "email": "tech@example.com",
	  "external_accounts": {
		"object": "list",
		"data": [
		  {
			"id": "ba_fake123456789",
			"object": "bank_account",
			"account": "acct_fake123456789",
			"account_holder_name": "カ）マイショップインク",
			"account_holder_type": null,
			"bank_name": "三井住友銀行",
			"country": "JP",
			"currency": "jpy",
			"default_for_currency": true,
			"fingerprint": "VkINqgzE0zu5x1xw",
			"last4": "2235",
			"metadata": {},
			"routing_number": "0009218",
			"status": "new"
		  }
		],
		"has_more": false,
		"url": "/v1/accounts/acct_fake123456789/external_accounts"
	  },
	  "metadata": {},
	  "payouts_enabled": true,
	  "requirements": {
		"current_deadline": null,
		"currently_due": [],
		"disabled_reason": null,
		"eventually_due": [],
		"past_due": [],
		"pending_verification": []
	  },
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
		  "statement_descriptor": "MYSHOP, IN",
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
	  "tos_acceptance": {
		"date": 1484979187,
		"ip": "114.17.230.189",
		"user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
	  },
	  "type": "custom"
	}

=head1 HISTORY

=head2 v0.1

Initial version

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
