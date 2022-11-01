##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/15
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/balance/balance_object
package Net::API::Stripe::Balance;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

## Array of Net::API::Stripe::Connect::Transfer
sub available { return( shift->_set_get_object_array( 'available', 'Net::API::Stripe::Connect::Transfer', @_ ) ); }

## Array of Net::API::Stripe::Balance::ConnectReserved
sub connect_reserved { return( shift->_set_get_object_array( 'connect_reserved', 'Net::API::Stripe::Balance::ConnectReserved', @_ ) ); }

sub instant_available { return( shift->_set_get_object_array( 'instant_available', 'Net::API::Stripe::Balance::Pending', @_ ) ); }

sub issuing { return( shift->_set_get_class( 'issuing',
    {
    available   => { type => 'object', package => 'Net::API::Stripe::Balance::Pending' },
    }, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

# Array of Net::API::Stripe::Balance::Pending
sub pending { return( shift->_set_get_object_array( 'pending', 'Net::API::Stripe::Balance::Pending', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance - The Balance object

=head1 SYNOPSIS

    my $object = $stripe->balances( 'retrieve' ) || die( $stripe->error );

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

This is an object representing your Stripe balance. You can retrieve it to see the balance currently on your Stripe account.

You can also retrieve the balance history, which contains a list of transactions (L<https://stripe.com/docs/reporting/balance-transaction-types>) that contributed to the balance (charges, payouts, and so forth).

The available and pending amounts for each currency are broken down further by payment source types.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Balance> object.

=head1 METHODS

=head2 object string, value is "balance"

String representing the object’s type. Objects of the same type share the same value.

=head2 available array of L<Net::API::Stripe::Connect::Transfer>

Funds that are available to be transferred or paid out, whether automatically by Stripe or explicitly via the Transfers API or Payouts API. The available balance for each currency and payment type can be found in the source_types property.

Currently this is an array of L<Net::API::Stripe::Connect::Transfer>, but I am considering revising that in light of the documentation of the Stripe API.

=head2 amount integer

Balance amount.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 source_types hash

Breakdown of balance by source types.

=over 4

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

=back

=head2 connect_reserved array of L<Net::API::Stripe::Balance::ConnectReserved> objects.

Funds held due to negative balances on connected Custom accounts. The connect reserve balance for each currency and payment type can be found in the source_types property.

=over 4

=item I<amount> integer

Balance amount.

=item I<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item I<source_types> hash

Breakdown of balance by source types.

=back

=head2 instant_available array of hashes

Funds that can be paid out using Instant Payouts.

This is a L<Net::API::Stripe::Balance::Pending> object.

It contains the following properties:

=over 4

=item I<amount> integer

Balance amount.

=item I<currency> number

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item I<source_types> hash

Breakdown of balance by source types.

It contains the following sub properties:

=over 8

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

=item I<fpx> integer

Amount for FPX.

=back

=back

=head2 issuing hash

Funds that can be spent on your Issued Cards.

It has the following properties:

=over 4

=item I<available> array

Funds that are available for use.

When expanded, this is a L<Net::API::Stripe::Balance::Pending> object.

It has the following properties:

=over 8

=item I<amount> integer

Balance amount.

=item I<currency> number

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item I<source_types> hash

Breakdown of balance by source types.

It contains the following sub properties:

=over 12

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

=item I<fpx> integer

Amount for FPX.

=back

=back

=back

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 pending array of L<Net::API::Stripe::Balance::Pending> objects.

Funds that are not yet available in the balance, due to the 7-day rolling pay cycle. The pending balance for each currency, and for each payment type, can be found in the source_types property.

=over 4

=item I<amount> integer

Balance amount.

=item I<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item I<source_types> hash

Breakdown of balance by source types.

=back

=head1 API SAMPLE

    {
      "object": "balance",
      "available": [
        {
          "amount": 0,
          "currency": "jpy",
          "source_types": {
            "card": 0
          }
        }
      ],
      "connect_reserved": [
        {
          "amount": 0,
          "currency": "jpy"
        }
      ],
      "livemode": false,
      "pending": [
        {
          "amount": 7712,
          "currency": "jpy",
          "source_types": {
            "card": 7712
          }
        }
      ]
    }

=head1 HISTORY

=head2 v0.100.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://stripe.com/docs/api/balance>, L<https://stripe.com/docs/connect/account-balances>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
