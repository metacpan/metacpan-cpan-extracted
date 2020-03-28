##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Settings/Payments.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Settings::Payments;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub statement_descriptor_kana { return( shift->_set_get_scalar( 'statement_descriptor_kana', @_ ) ); }

sub statement_descriptor_kanji { return( shift->_set_get_scalar( 'statement_descriptor_kanji', @_ ) ); }


1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Settings::Payments - A Stripe Account Settings Object for Payments

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Settings used to configure the account within the Stripe dashboard.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<statement_descriptor> string

The default text that appears on credit card statements when a charge is made. This field prefixes any dynamic statement_descriptor specified on the charge.

=item B<statement_descriptor_kana> string

The Kana variation of the default text that appears on credit card statements when a charge is made (Japan only)

=item B<statement_descriptor_kanji> string

The Kanji variation of the default text that appears on credit card statements when a charge is made (Japan only)

=back

=head1 API SAMPLE

	{
	  "id": "acct_19eGgRCeyNCl6xYZ",
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
		  "icon": "file_1DLf5rCeyNCl6fY2kS4e5hMT",
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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/accounts/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
