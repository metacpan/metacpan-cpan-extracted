##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Settings/Payouts.pm
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
package Net::API::Stripe::Connect::Account::Settings::Payouts;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub debit_negative_balances { return( shift->_set_get_boolean( 'debit_negative_balances', @_ ) ); }

sub schedule
{
    return( shift->_set_get_class( 'schedule',
    {
    delay_days => { type => 'integer' },
    interval => { type => 'scalar' },
    monthly_anchor => { type => 'integer' },
    weekly_anchor => { type => 'scalar' }
    }, @_ ) );
}

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }


1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Settings::Payouts - A Stripe Account Settings Object for Payouts

=head1 SYNOPSIS

    my $payouts = $stripe->account->settings->payouts({
        debit_negative_balances => $stripe->false,
        schedule => 
            {
            delay_days => 7,
            interval => 'weekly',
            weekly_anchor => 'monday',
            },
        statement_descriptor => 'Weekly payout',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Settings used to configure the account within the Stripe dashboard.

This is instantiated by method B<payouts> from module L<Net::API::Stripe::Connect::Account::Settings>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Settings::Payouts> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<debit_negative_balances> boolean

A Boolean indicating if Stripe should try to reclaim negative balances from an attached bank account. See L<Stripe Understanding Connect Account Balances documentation|https://stripe.com/docs/connect/account-balances> for details. Default value is true for Express accounts and false for Custom accounts.

=item B<schedule> hash

Details on when funds from charges are available, and when they are paid out to an external account. See L<Stripe Setting Bank and Debit Card Payouts documentation|https://stripe.com/docs/connect/bank-transfers#payout-information> for details.

This is a dynamic class with name L<Net::API::Stripe::Connect::Account::Settings::Payouts::Schedule>. It is created using method B<_set_get_class> from module L<Module::Generic>

=over 8

=item I<delay_days> positive integer or zero

The number of days charges for the account will be held before being paid out.

=item I<interval> string

How frequently funds will be paid out. One of manual (payouts only created via API call), daily, weekly, or monthly.

=item I<monthly_anchor> positive integer or zero

The day of the month funds will be paid out. Only shown if interval is monthly. Payouts scheduled between the 29th and 31st of the month are sent on the last day of shorter months.

=item I<weekly_anchor> string

The day of the week funds will be paid out, of the style ‘monday’, ‘tuesday’, etc. Only shown if interval is weekly.

=back

=item B<statement_descriptor> string

The text that appears on the bank account statement for payouts. If not set, this defaults to the platform’s bank descriptor as set in the Dashboard.

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
