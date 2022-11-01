##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/TestClock.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/11
## Modified 2022/07/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::TestClock;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }



1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Billing::TestClock - The test clock object

=head1 SYNOPSIS

    use Net::API::Stripe::Billing::TestClock;
    my $this = Net::API::Stripe::Billing::TestClock->new || 
        die( Net::API::Stripe::Billing::TestClock->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A test clock enables deterministic control over objects in testmode. With a test clock, you can create objects at a frozen time in the past or future, and advance to a specific future time to observe webhooks and state changes. After the clock advances, you can either validate the current state of your scenario (and test your assumptions), change the current state of your scenario (and test more complex scenarios), or keep advancing forward in time.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Billing::TaxID> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "tax_id"

String representing the object’s type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 deletes_after timestamp

Time at which this clock is scheduled to auto delete.

=head2 frozen_time timestamp

Time at which all objects belonging to this clock are frozen.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 name string

The custom name supplied at creation.

=head2 status enum

The status of the Test Clock.

Possible enum values

=over 4

=item * C<ready>

All test clock objects have advanced to the frozen_time.

=item * C<advancing>

In the process of advancing time for the test clock objects.

=item * C<internal_failure>

Failed to advance time. Future requests to advance time will fail.

=back

=head1 API SAMPLE

    {
      "id": "clock_1LKKwJCeyNCl6fY2ggn0eCSi",
      "object": "test_helpers.test_clock",
      "created": 1657539491,
      "deletes_after": 1658144291,
      "frozen_time": 1577836800,
      "livemode": false,
      "name": null,
      "status": "ready"
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/test_clocks/object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
