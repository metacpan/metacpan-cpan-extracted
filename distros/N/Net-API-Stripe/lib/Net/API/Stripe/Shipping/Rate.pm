##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Shipping/Rate
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/24
## Modified 2022/01/24
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Shipping::Rate;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub delivery_estimate { return( shift->_set_get_class( 'delivery_estimate',
{
  maximum => {
               definition => { unit => { type => "scalar" }, value => { type => "number" } },
               type => "class",
             },
  minimum => {
               definition => { unit => { type => "scalar" }, value => { type => "number" } },
               type => "class",
             },
}, @_ ) ); }

sub display_name { return( shift->_set_get_scalar( 'display_name', @_ ) ); }

sub fixed_amount { return( shift->_set_get_object( 'fixed_amount', 'Net::API::Stripe::Balance::ConnectReserved', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub tax_behavior { return( shift->_set_get_scalar( 'tax_behavior', @_ ) ); }

sub tax_code { return( shift->_set_get_scalar_or_object( 'tax_code', '', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Shipping::Rate - The shipping rate object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Shipping rates describe the price of shipping presented to your customers and can be applied to L<Checkout Sessions|Checkout Sessions> to collect shipping costs.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 active boolean

Whether the shipping rate can be used for new purchases. Defaults to C<true>.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 delivery_estimate hash

The estimated range for how long shipping will take, meant to be displayable to the customer. This will appear on CheckoutSessions.

It has the following properties:

=over 4

=item I<maximum> hash

The upper bound of the estimated range. If empty, represents no upper bound i.e., infinite.

=over 8

=item I<unit> string

A unit of time.

=item I<value> integer

Must be greater than 0.

=back

=item I<minimum> hash

The lower bound of the estimated range. If empty, represents no lower bound.

=over 8

=item I<unit> string

A unit of time.

=item I<value> integer

Must be greater than 0.

=back


=back

=head2 display_name string

The name of the shipping rate, meant to be displayable to the customer. This will appear on CheckoutSessions.

=head2 fixed_amount object

Describes a fixed amount to charge for shipping. Must be present if type is C<fixed_amount>.

This is a L<Net::API::Stripe::Balance::ConnectReserved> object.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|key-value pairs> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 tax_behavior string

Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of C<inclusive>, C<exclusive>, or C<unspecified>. 

=head2 tax_code expandable

A L<tax code|tax code> ID. The Shipping tax code is C<txcd_92010001>.

When expanded this is an L<Net::API::Stripe::Product::TaxCode> object.

=head2 type string

The type of calculation to use on the shipping rate. Can only be C<fixed_amount> for now.

=head1 API SAMPLE

    {
      "id": "shr_1KJGon2eZvKYlo2C3Hc5P110",
      "object": "shipping_rate",
      "active": true,
      "created": 1642508985,
      "delivery_estimate": null,
      "display_name": "Ground shipping",
      "fixed_amount": {
        "amount": 500,
        "currency": "usd"
      },
      "livemode": false,
      "metadata": {
      },
      "tax_behavior": "unspecified",
      "tax_code": null,
      "type": "fixed_amount"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api#shipping_rate_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
