##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Quote
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/24
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Quote;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount_subtotal { return( shift->_set_get_number( 'amount_subtotal', @_ ) ); }

sub amount_total { return( shift->_set_get_number( 'amount_total', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub application_fee_amount { return( shift->_set_get_number( 'application_fee_amount', @_ ) ); }

sub application_fee_percent { return( shift->_set_get_number( 'application_fee_percent', @_ ) ); }

sub automatic_tax { return( shift->_set_get_class( 'automatic_tax',
{
    enabled => { type => "boolean" },
    status => { type => "scalar" },
}, @_ ) ); }

sub collection_method { return( shift->_set_get_scalar( 'collection_method', @_ ) ); }

sub computed { return( shift->_set_get_class( 'computed',
{
  recurring => { package => "Net::API::Stripe::Checkout::Session", type => "object" },
  upfront   => { package => "Net::API::Stripe::Checkout::Session", type => "object" },
}, @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub default_tax_rates { return( shift->_set_get_scalar_or_object( 'default_tax_rates', 'Net::API::Stripe::Tax::Rate', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub discounts { return( shift->_set_get_scalar_or_object( 'discounts', 'Net::API::Stripe::Billing::Discount', @_ ) ); }

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ); }

sub footer { return( shift->_set_get_scalar( 'footer', @_ ) ); }

sub from_quote { return( shift->_set_get_class( 'from_quote',
{
  is_revision => { type => "boolean" },
  quote => {
    package => "Net::API::Stripe::Billing::Quote",
    type => "scalar_or_object",
  },
}, @_ ) ); }

sub header { return( shift->_set_get_scalar( 'header', @_ ) ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub invoice_settings { return( shift->_set_get_object( 'invoice_settings', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub line_items { return( shift->_set_get_object( 'line_items', 'Net::API::Stripe::List', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub number { return( shift->_set_get_scalar( 'number', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_class( 'status_transitions',
{
  accepted_at  => { type => "datetime" },
  canceled_at  => { type => "datetime" },
  finalized_at => { type => "datetime" },
}, @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_data { return( shift->_set_get_object( 'subscription_data', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_schedule { return( shift->_set_get_scalar_or_object( 'subscription_schedule', 'Net::API::Stripe::Billing::Subscription::Schedule', @_ ) ); }

sub test_clock { return( shift->_set_get_scalar_or_object( 'test_clock', 'Net::API::Stripe::Billing::TestClock', @_ ) ); }

sub total_details { return( shift->_set_get_class( 'total_details',
{
  amount_discount => { type => "number" },
  amount_shipping => { type => "number" },
  amount_tax      => { type => "number" },
  breakdown       => {
                       definition => {
                         discounts => {
                           definition => 
                           {
                            amount => { type => "number" },
                            discount => { package => "Net::API::Stripe::Billing::Discount", type => "object" }
                           },
                           type => "class_array",
                         },
                         taxes => {
                           definition => {
                             amount => { type => "number" },
                             rate   => { package => "Net::API::Stripe::Tax::Rate", type => "object" },
                           },
                           type => "class_array",
                         },
                       },
                       type => "class",
                     },
}, @_ ) ); }

sub transfer_data { return( shift->_set_get_object( 'transfer_data', 'Net::API::Stripe::Charge', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Quote - The quote object

=head1 SYNOPSIS

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A Quote is a way to model prices that you'd like to provide to a customer.
Once accepted, it will automatically create an invoice, subscription or subscription schedule.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount_subtotal integer

Total before any discounts or taxes are applied.

=head2 amount_total integer

Total after discounts and taxes are applied.

=head2 application_fee_amount integer

The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. Only applicable if there are no line items with recurring prices on the quote.

=head2 application_fee_percent decimal

A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice subtotal that will be transferred to the application owner's Stripe account. Only applicable if there are line items with recurring prices on the quote.

=head2 automatic_tax hash

Settings for automatic tax lookup for this quote and resulting invoices and subscriptions.

It has the following properties:

=over 4

=item I<enabled> boolean

Automatically calculate taxes

=item I<status> string

The status of the most recent automated tax calculation for this quote.


=back

=head2 collection_method string

Either C<charge_automatically>, or C<send_invoice>. When charging automatically, Stripe will attempt to pay invoices at the end of the subscription cycle or on finalization using the default payment method attached to the subscription or customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions. Defaults to C<charge_automatically>.

=head2 computed hash

The definitive totals and line items for the quote, computed based on your inputted line items as well as other configuration such as trials. Used for rendering the quote to your customer.

It has the following properties:

=over 4

=item I<recurring> hash

The definitive totals and line items the customer will be charged on a recurring basis. Takes into account the line items with recurring prices and discounts with C<duration=forever> coupons only. Defaults to C<null> if no inputted line items with recurring prices.

When expanded, this is a L<Net::API::Stripe::Checkout::Session> object.

=item I<upfront> hash

The definitive upfront totals and line items the customer will be charged on the first invoice.

When expanded, this is a L<Net::API::Stripe::Checkout::Session> object.


=back

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency string

Three-letter L<ISO currency code|ISO currency code>, in lowercase. Must be a L<supported currency|supported currency>.

=head2 customer expandable

The customer which this quote belongs to. A customer is required before finalizing the quote. Once specified, it cannot be changed.

When expanded this is an L<Net::API::Stripe::Customer> object.

=head2 default_tax_rates expandable

The tax rates applied to this quote.

When expanded this is an L<Net::API::Stripe::Tax::Rate> object.

=head2 description string

A description that will be displayed on the quote PDF.

=head2 discounts expandable

The discounts applied to this quote.

When expanded this is an L<Net::API::Stripe::Billing::Discount> object.

=head2 expires_at timestamp

The date on which the quote will be canceled if in C<open> or C<draft> status. Measured in seconds since the Unix epoch.

=head2 footer string

A footer that will be displayed on the quote PDF.

=head2 from_quote hash

Details of the quote that was cloned. See the L<cloning documentation|cloning documentation> for more details.

It has the following properties:

=over 4

=item I<is_revision> boolean

Whether this quote is a revision of a different quote.

=item I<quote> string expandable

The quote that was cloned.

When expanded this is an L<Net::API::Stripe::Billing::Quote> object.


=back

=head2 header string

A header that will be displayed on the quote PDF.

=head2 invoice expandable

The invoice that was created from this quote.

When expanded this is an L<Net::API::Stripe::Billing::Invoice> object.

=head2 invoice_settings object

All invoices will be billed using the specified settings.

This is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 line_items object

A list of items the customer is being quoted for.

This is a L<Net::API::Stripe::List> object.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|key-value pairs> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 number string

A unique number that identifies this particular quote. This number is assigned once the quote is L<finalized|finalized>.

=head2 on_behalf_of expandable

The account on behalf of which to charge. See the L<Connect documentation|Connect documentation> for details.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 status string

The status of the quote.

=head2 status_transitions hash

The timestamps of which the quote transitioned to a new status.

It has the following properties:

=over 4

=item I<accepted_at> timestamp

The time that the quote was accepted. Measured in seconds since Unix epoch.

=item I<canceled_at> timestamp

The time that the quote was canceled. Measured in seconds since Unix epoch.

=item I<finalized_at> timestamp

The time that the quote was finalized. Measured in seconds since Unix epoch.


=back

=head2 subscription expandable

The subscription that was created or updated from this quote.

When expanded this is an L<Net::API::Stripe::Billing::Subscription> object.

=head2 subscription_data object

When creating a subscription or subscription schedule, the specified configuration data will be used. There must be at least one line item with a recurring price for a subscription or subscription schedule to be created.

This is a L<Net::API::Stripe::Billing::Subscription> object.

=head2 subscription_schedule expandable

The subscription schedule that was created or updated from this quote.

When expanded this is an L<Net::API::Stripe::Billing::Subscription::Schedule> object.

=head2 total_details hash

Tax and discount details for the computed total amount.

It has the following properties:

=over 4

=item I<amount_discount> integer

This is the sum of all the line item discounts.

=item I<amount_shipping> integer

This is the sum of all the line item shipping amounts.

=item I<amount_tax> integer

This is the sum of all the line item tax amounts.

=item I<breakdown> hash

Breakdown of individual tax and discount amounts that add up to the totals.

=over 8

=item I<discounts> array

The aggregated line item discounts.

=over 12

=item I<amount> integer

The amount discounted.

=item I<discount> hash

The discount applied.

=back

=item I<taxes> array

The aggregated line item tax amounts by rate.

=over 12

=item I<amount> integer

Amount of tax applied for this rate.

=item I<rate> hash

The tax rate applied.

When expanded, this is a L<Net::API::Stripe::Billing::Quote> object.

=back

=back


=back

=head2 transfer_data object

The account (if any) the payments will be attributed to for tax reporting, and where funds from each payment will be transferred to for each of the invoices.

This is a L<Net::API::Stripe::Charge> object.

=head1 API SAMPLE

    {
      "id": "qt_1KJGon2eZvKYlo2CYE6HxURp",
      "object": "quote",
      "amount_subtotal": 0,
      "amount_total": 0,
      "application_fee_amount": null,
      "application_fee_percent": null,
      "automatic_tax": {
        "enabled": false,
        "status": null
      },
      "collection_method": "charge_automatically",
      "computed": {
        "recurring": null,
        "upfront": {
          "amount_subtotal": 0,
          "amount_total": 0,
          "total_details": {
            "amount_discount": 0,
            "amount_shipping": 0,
            "amount_tax": 0
          }
        }
      },
      "created": 1642508985,
      "currency": "usd",
      "customer": "cus_AJ6yY15pe9xOZe",
      "default_tax_rates": [
    
      ],
      "description": null,
      "discounts": [
    
      ],
      "expires_at": 1645100985,
      "footer": null,
      "from_quote": null,
      "header": null,
      "invoice": null,
      "invoice_settings": {
        "days_until_due": null
      },
      "livemode": false,
      "metadata": {
      },
      "number": null,
      "on_behalf_of": null,
      "status": "draft",
      "status_transitions": {
        "accepted_at": null,
        "canceled_at": null,
        "finalized_at": null
      },
      "subscription": null,
      "subscription_data": {
        "effective_date": null,
        "trial_period_days": null
      },
      "subscription_schedule": null,
      "total_details": {
        "amount_discount": 0,
        "amount_shipping": 0,
        "amount_tax": 0
      },
      "transfer_data": null
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api#quote_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
