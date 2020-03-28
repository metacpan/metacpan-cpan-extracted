##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/UsageRecord.pm
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
## https://stripe.com/docs/api/usage_records
package Net::API::Stripe::Billing::UsageRecord;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub quantity { shift->_set_get_number( 'quantity', @_ ); }

sub subscription_item { shift->_set_get_scalar( 'subscription_item', @_ ); }

sub timestamp { shift->_set_get_datetime( 'timestamp', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::UsageRecord - A Stripe Usage Record Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Usage records allow you to report customer usage and metrics to Stripe for metered billing of subscription plans.

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

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "usage_record"

String representing the object’s type. Objects of the same type share the same value.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<quantity> positive integer or zero

The usage quantity for the specified date.

=item B<subscription_item> string

The ID of the subscription item this usage record contains data for.

=item B<timestamp> timestamp

The timestamp when this usage occurred.

=back

=head1 API SAMPLE

	{
	  "id": "mbur_1FUtZzCeyNCl6fY2RtcTFLiU",
	  "object": "usage_record",
	  "livemode": false,
	  "quantity": 100,
	  "subscription_item": "si_G0vQtt5chBNkN7",
	  "timestamp": 1571397911
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/usage_records>, L<https://stripe.com/docs/billing/subscriptions/metered-billing>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
