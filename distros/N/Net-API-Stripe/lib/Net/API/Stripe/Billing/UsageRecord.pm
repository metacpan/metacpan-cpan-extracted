##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/UsageRecord.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/usage_records
package Net::API::Stripe::Billing::UsageRecord;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub subscription_item { return( shift->_set_get_scalar( 'subscription_item', @_ ) ); }

sub timestamp { return( shift->_set_get_datetime( 'timestamp', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::UsageRecord - A Stripe Usage Record Object

=head1 SYNOPSIS

    my $usage_record = $stripe->usage_record({
        quantity => 1,
        subscription_item => $subscription_item_object,
        # Can be a unix timestamp or an iso 8601 date
        timestamp => '2020-04-01',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Usage records allow you to report customer usage and metrics to Stripe for metered billing of subscription plans.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::UsageRecord> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "usage_record"

String representing the object’s type. Objects of the same type share the same value.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 quantity positive integer or zero

The usage quantity for the specified date.

=head2 subscription_item string

The ID of the subscription item this usage record contains data for.

=head2 timestamp timestamp

The timestamp when this usage occurred.

=head1 API SAMPLE

    {
      "id": "mbur_fake123456789",
      "object": "usage_record",
      "livemode": false,
      "quantity": 100,
      "subscription_item": "si_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
