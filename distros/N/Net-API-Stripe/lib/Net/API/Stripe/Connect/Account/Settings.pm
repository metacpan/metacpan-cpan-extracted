##----------------------------------------------------------------------------
## Stripe API - ~/usr/local/src/perl/Net-API-Stripe/lib/Net/API/Stripe/Connect/Account/Settings.pm
## Version v0.102.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Settings;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.102.0';
};

use strict;
use warnings;

sub bacs_debit_payments { return( shift->_set_get_object( 'bacs_debit_payments', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub branding { return( shift->_set_get_object( 'branding', 'Net::API::Stripe::Connect::Account::Branding', @_ ) ); }

sub card_issuing { return( shift->_set_get_object( 'card_issuing', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub card_payments { return( shift->_set_get_object( 'card_payments', 'Net::API::Stripe::Connect::Account::Settings::CardPayments', @_ ) ); }

sub dashboard { return( shift->_set_get_object( 'dashboard', 'Net::API::Stripe::Connect::Account::Settings::Dashboard', @_ ) ); }

sub payments { return( shift->_set_get_object( 'payments', 'Net::API::Stripe::Connect::Account::Settings::Payments', @_ ) ); }

sub payouts { return( shift->_set_get_object( 'payouts', 'Net::API::Stripe::Connect::Account::Settings::Payouts', @_ ) ); }

sub sepa_debit_payments { return( shift->_set_get_class( 'sepa_debit_payments',
{ creditor_id => { type => "scalar" } }, @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Settings - A Stripe Account Settings Object

=head1 SYNOPSIS

    my $settings = $stripe->account->settings({
        branding => $branding_object,
        card_payments => $card_payments_object,
        dashboard => $dashboard_object,
        payments => $payments_object,
        payouts => $payouts_object,
    });

=head1 VERSION

    v0.102.0

=head1 DESCRIPTION

Options for customizing how the account functions within Stripe.

This is instantiated by method B<settings> from module L<Net::API::Stripe::Connect::Account>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Settings> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 bacs_debit_payments object

Settings specific to Bacs Direct Debit on the account.

This is a L<Net::API::Stripe::Connect::Account> object.

=head2 branding hash

Settings used to apply the account’s branding to email receipts, invoices, Checkout, and other products.

This is a L<Net::API::Stripe::Connect::Account::Branding> object.

=head2 card_issuing object

Settings specific to the account's use of the Card Issuing product.

This is a L<Net::API::Stripe::Connect::Account> object.

=head2 card_payments hash

Settings specific to card charging on the account.

This is a L<Net::API::Stripe::Connect::Account::Settings::CardPayments> object.

=head2 dashboard hash

Settings used to configure the account within the Stripe dashboard.

This is a L<Net::API::Stripe::Connect::Account::Settings::Dashboard> object.

=head2 payments hash

Settings that apply across payment methods for charging on the account.

This is a L<Net::API::Stripe::Connect::Account::Settings::Payments> object.

=head2 payouts hash

Settings specific to the account’s payouts. This is a L<Net::API::Stripe::Connect::Account::Settings::Payouts> object.

=head2 sepa_debit_payments hash

Settings specific to SEPA Direct Debit on the account.

It has the following properties:

=over 4

=item C<creditor_id> string

SEPA creditor identifier that identifies the company making the payment.

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
