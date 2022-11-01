##----------------------------------------------------------------------------
## Stripe API - ~/usr/local/src/perl/Net-API-Stripe/lib/Net/API/Stripe/Mandate.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/25
## Modified 2020/11/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Mandate;
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

sub customer_acceptance { return( shift->_set_get_class( 'customer_acceptance',
{
  accepted_at => { type => "datetime" },
  offline => { type => "hash" },
  online => {
    definition => {
      ip_address => { type => "scalar" },
      user_agent => { type => "scalar" },
    },
    type => "class",
  },
  type => { type => "scalar" },
}, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

# NOTE: multi_use needs to be an object, so we make it a dynamic class even though it has no properties as of 2022-08-10
sub multi_use { return( shift->_set_get_class( 'multi_use', {}, @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_details { return( shift->_set_get_object( 'payment_method_details', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub single_use
{
    return( shift->_set_get_class( 'single_use', 
        {
        amount => { type => 'number' },
        currency => { type => 'scalar' },
        }, @_ )
    );
}

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Mandate - A Stripe Mandate Object

=head1 SYNOPSIS

    my $mandate = $stripe->mandate({
        customer_acceptance => 
        {
            accepted_at => '2020-04-12T07:30:45',
            offline => {},
            online => {},
            type => 'online',
        },
        payment_method => $payment_method_object,
        single_use =>
        {
            amount => 2000,
            currency => 'jpy',
        },
        status => 'active',
        type => 'mandate',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A Mandate is a record of the permission a customer has given you to debit their payment method.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Mandate> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "mandate"

String representing the object’s type. Objects of the same type share the same value.

=head2 customer_acceptance hash

Details about the customer's acceptance of the mandate.

It has the following properties:

=over 4

=item I<accepted_at> timestamp

The time at which the customer accepted the Mandate.

=item I<offline> hash

If this is a Mandate accepted offline, this hash contains details about the offline acceptance.

=over 8

=item I<offline>

This is an empty hash.

=back

=item I<online> hash

If this is a Mandate accepted online, this hash contains details about the online acceptance.

=over 8

=item I<ip_address> string

The IP address from which the Mandate was accepted by the customer.

=item I<user_agent> string

The user agent of the browser from which the Mandate was accepted by the customer.

=back

=item I<type> string

The type of customer acceptance information included with the Mandate. One of C<online> or C<offline>.

=back

head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 multi_use hash

If this is a multi_use mandate, this hash contains details about the mandate.

=head2  payment_method string expandable

ID of the payment method associated with this mandate.

=head2 payment_method_details object

Additional mandate information specific to the payment method type.

This is a L<Net::API::Stripe::Payment::Method> object.

=head2 single_use hash

If this is a single_use mandate, this hash contains details about the mandate.

=over 4

=item I<amount> integer

On a single use mandate, the amount of the payment.

=item I<currency> currency

On a single use mandate, the currency of the payment.

=back

=head2 status string

The status of the Mandate, one of active, inactive, or pending. The Mandate can be used to initiate a payment only if status=active.

=head2 type string

The type of the mandate, one of multi_use or single_use

=head1 API SAMPLE

    {
      "id": "mandate_123456789",
      "object": "mandate",
      "customer_acceptance": {
        "accepted_at": 123456789,
        "online": {
          "ip_address": "127.0.0.0",
          "user_agent": "device"
        },
        "type": "online"
      },
      "livemode": false,
      "multi_use": {},
      "payment_method": "pm_123456789",
      "payment_method_details": {
        "sepa_debit": {
          "reference": "123456789",
          "url": ""
        },
        "type": "sepa_debit"
      },
      "status": "active",
      "type": "multi_use"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>, L<https://stripe.com/docs/api/mandates/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
