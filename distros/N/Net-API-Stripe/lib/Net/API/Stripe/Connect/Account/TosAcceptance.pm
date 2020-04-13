##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/TosAcceptance.pm
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
package Net::API::Stripe::Connect::Account::TosAcceptance;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub date { shift->_set_get_datetime( 'date', @_ ); }

sub ip { shift->_set_get_scalar( 'ip', @_ ); }

sub user_agent { shift->_set_get_scalar( 'user_agent', @_ ); }

sub iovation_blackbox { shift->_set_get_scalar( 'iovation_blackbox', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::TosAcceptance - An interface to Stripe API

=head1 SYNOPSIS

    my $tos_ok = $stripe->account->tos_acceptance({
        date => '2020-04-12',
        ip => '1.2.3.4',
        user_agent => 'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.66 Safari/537.36',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Details on the acceptance of the Stripe Services Agreement

This is instantiated by method B<tos_acceptance> from module L<Net::API::Stripe::Connect::Account>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::TosAcceptance> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<date> timestamp

The Unix timestamp marking when the Stripe Services Agreement was accepted by the account representative

=item B<ip> string

The IP address from which the Stripe Services Agreement was accepted by the account representative

=item B<user_agent> string

The user agent of the browser from which the Stripe Services Agreement was accepted by the account representative

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
