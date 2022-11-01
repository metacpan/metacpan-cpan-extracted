##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Transaction.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/issuing/transactions
package Net::API::Stripe::Issuing::Transaction;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_details { return( shift->_set_get_class( 'amount_details', {
    atm_fee => { type => "number" }
}, @_ ) ); }

sub authorization { return( shift->_set_get_scalar_or_object( 'authorization', 'Net::API::Stripe::Issuing::Authorization', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub card { return( shift->_set_get_scalar_or_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ) ); }

sub cardholder { return( shift->_set_get_scalar_or_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub dispute { return( shift->_set_get_scalar_or_object( 'dispute', 'Net::API::Stripe::Issuing::Dispute', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub merchant_amount { return( shift->_set_get_number( 'merchant_amount', @_ ) ); }

sub merchant_currency { return( shift->_set_get_scalar( 'merchant_currency', @_ ) ); }

sub merchant_data { return( shift->_set_get_object( 'merchant_data', 'Net::API::Stripe::Issuing::MerchantData', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub purchase_details { return( shift->_set_get_class( 'purchase_details',
{
  flight    => {
                 definition => {
                   departure_at   => { type => "number" },
                   passenger_name => { type => "scalar" },
                   refundable     => { type => "boolean" },
                   segments       => {
                                       definition => {
                                         arrival_airport_code   => { type => "scalar" },
                                         carrier                => { type => "scalar" },
                                         departure_airport_code => { type => "scalar" },
                                         flight_number          => { type => "scalar" },
                                         service_class          => { type => "scalar" },
                                         stopover_allowed       => { type => "boolean" },
                                       },
                                       type => "class_array",
                                     },
                   travel_agency  => { type => "scalar" },
                 },
                 type => "class",
               },
  fuel      => {
                 definition => {
                   type => { type => "scalar" },
                   unit => { type => "scalar" },
                   unit_cost_decimal => { type => "number" },
                   volume_decimal => { type => "number" },
                 },
                 type => "class",
               },
  lodging   => {
                 definition => { check_in_at => { type => "number" }, nights => { type => "number" } },
                 type => "class",
               },
  receipt   => {
                 definition => {
                   description => { type => "scalar" },
                   quantity    => { type => "number" },
                   total       => { type => "number" },
                   unit_cost   => { type => "number" },
                 },
                 type => "class_array",
               },
  reference => { type => "scalar" },
}, @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub wallet { return( shift->_set_get_scalar( 'wallet', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Transaction - A Stripe Issuing Transaction Object

=head1 SYNOPSIS

    my $trans = $stripe->issuing_transaction({
        amount => 2000,
        authorization => $authorization_object,
        balance_transaction => $balance_transaction,
        card => $card_object,
        currency => 'jpy',
        merchant_amount => 2000,
        merchant_currency => 'jpy',
        metadata => { transaction_id => 123, customer_id > 456 },
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Any use of an issued card (L<https://stripe.com/docs/issuing>) that results in funds entering or leaving your Stripe account, such as a completed purchase or refund, is represented by an Issuing Transaction object.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Transaction> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "issuing.transaction"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The transaction amount, which will be reflected in your balance. This amount is in your currency and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=head2 amount_details hash

Detailed breakdown of amount components. These amounts are denominated in `currency` and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

It has the following properties:

=over 4

=item I<atm_fee> integer

The fee charged by the ATM for the cash withdrawal.

=back

=head2 authorization string (expandable)

The Authorization object that led to this transaction.

When expanded, this is a L<Net::API::Stripe::Issuing::Authorization> object.

=head2 balance_transaction string (expandable)

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 card string (expandable)

The card used to make this transaction.

When expanded, this is a L<Net::API::Stripe::Payment::Card> object.

=head2 cardholder string (expandable)

The cardholder to whom this transaction belongs.

When expanded, this is a L<Net::API::Stripe::Issuing::Card::Holder> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 dispute string (expandable)

When expanded, this is a L<Net::API::Stripe::Issuing::Dispute> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 merchant_amount integer

The amount that the merchant will receive, denominated in L</merchant_currency> and in the smallest currency unit. It will be different from L</amount> if the merchant is taking payment in a different currency.

=head2 merchant_currency currency

The currency with which the merchant is taking payment.

=head2 merchant_data hash

More information about the user involved in the transaction.

This is a L<Net::API::Stripe::Issuing::MerchantData> object.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 purchase_details hash

Additional purchase information that is optionally provided by the merchant.

It has the following properties:

=over 4

=item I<flight> hash

Information about the flight that was purchased with this transaction.

=over 8

=item I<departure_at> integer

The time that the flight departed.

=item I<passenger_name> string

The name of the passenger.

=item I<refundable> boolean

Whether the ticket is refundable.

=item I<segments> array

The legs of the trip.

=over 12

=item I<arrival_airport_code> string

The three-letter IATA airport code of the flight's destination.

=item I<carrier> string

The airline carrier code.

=item I<departure_airport_code> string

The three-letter IATA airport code that the flight departed from.

=item I<flight_number> string

The flight number.

=item I<service_class> string

The flight's service class.

=item I<stopover_allowed> boolean

Whether a stopover is allowed on this flight.

=back

=item I<travel_agency> string

The travel agency that issued the ticket.

=back

=item I<fuel> hash

Information about fuel that was purchased with this transaction.

=over 8

=item I<type> string

The type of fuel that was purchased. One of `diesel`, `unleaded_plus`, `unleaded_regular`, `unleaded_super`, or `other`.

=item I<unit> string

The units for `volume_decimal`. One of `us_gallon` or `liter`.

=item I<unit_cost_decimal> decimal_string

The cost in cents per each unit of fuel, represented as a decimal string with at most 12 decimal places.

=item I<volume_decimal> decimal_string

The volume of the fuel that was pumped, represented as a decimal string with at most 12 decimal places.

=back

=item I<lodging> hash

Information about lodging that was purchased with this transaction.

=over 8

=item I<check_in_at> integer

The time of checking into the lodging.

=item I<nights> integer

The number of nights stayed at the lodging.

=back

=item I<receipt> array

The line items in the purchase.

=over 8

=item I<description> string

The description of the item. The maximum length of this field is 26 characters.

=item I<quantity> decimal

The quantity of the item.

=item I<total> integer

The total for this line item in cents.

=item I<unit_cost> integer

The unit cost of the item in cents.

=back

=item I<reference> string

A merchant-specific order number.

=back

=head2 type string

One of capture, refund, cash_withdrawal, refund_reversal, dispute, or dispute_loss.

=head2 wallet string

The digital wallet used for this transaction. One of C<apple_pay>, C<google_pay>, or C<samsung_pay>.

=head1 API SAMPLE

    {
      "id": "ipi_fake123456789",
      "object": "issuing.transaction",
      "amount": -100,
      "authorization": "iauth_fake123456789",
      "balance_transaction": null,
      "card": "ic_fake123456789",
      "cardholder": null,
      "created": 1571480456,
      "currency": "usd",
      "dispute": null,
      "livemode": false,
      "merchant_amount": -100,
      "merchant_currency": "usd",
      "merchant_data": {
        "category": "taxicabs_limousines",
        "city": "San Francisco",
        "country": "US",
        "name": "Rocket Rides",
        "network_id": "1234567890",
        "postal_code": "94107",
        "state": "CA",
        "url": null
      },
      "metadata": {},
      "type": "capture"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/transactions>, L<https://stripe.com/docs/issuing/transactions>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
