##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/TestHelpersTestClock.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::TestHelpersTestClock;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub deletes_after { return( shift->_set_get_datetime( 'deletes_after', @_ ) ); }

sub frozen_time { return( shift->_set_get_datetime( 'frozen_time', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::TestHelpersTestClock - The test clock object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A test clock enables deterministic control over objects in testmode. With a test clock, you can create objects at a frozen time in the past or future, and advance to a specific future time to observe webhooks and state changes. After the clock advances, you can either validate the current state of your scenario (and test your assumptions), change the current state of your scenario (and test more complex scenarios), or keep advancing forward in time.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 deletes_after timestamp

Time at which this clock is scheduled to auto delete.

=head2 frozen_time timestamp

Time at which all objects belonging to this clock are frozen.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 name string

The custom name supplied at creation.

=head2 status string

The status of the Test Clock.

=head1 API SAMPLE

[
   {
      "created" : "1662261084",
      "deletes_after" : "1662865884",
      "frozen_time" : "1577836800",
      "id" : "clock_1Le9F22eZvKYlo2CqGgA3AzY",
      "livemode" : 0,
      "name" : null,
      "object" : "test_helpers.test_clock",
      "status" : "ready"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/test_clocks>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
