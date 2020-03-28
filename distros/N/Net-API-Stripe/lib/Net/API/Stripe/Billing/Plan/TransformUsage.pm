##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Plan/TransformUsage.pm
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
package Net::API::Stripe::Billing::Plan::TransformUsage;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub divide_by { shift->_set_get_scalar( 'divide_by', @_ ); }

sub round { shift->_set_get_scalar( 'round', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Plan::TransformUsage - A Stripe Plan Transform Usage Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Apply a transformation to the reported usage or set quantity before computing the billed price. Cannot be combined with tiers.

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

=item B<divide_by> integer

Divide usage by this number.

=item B<round> string

After division, either round the result up or down.

=back

=head1 API SAMPLE

	{
	  "id": "expert-monthly-jpy",
	  "object": "plan",
	  "active": true,
	  "aggregate_usage": null,
	  "amount": 8000,
	  "amount_decimal": "8000",
	  "billing_scheme": "per_unit",
	  "created": 1507273129,
	  "currency": "jpy",
	  "interval": "month",
	  "interval_count": 1,
	  "livemode": false,
	  "metadata": {},
	  "nickname": null,
	  "product": "prod_BWtaL30HYleHZU",
	  "tiers": null,
	  "tiers_mode": null,
	  "transform_usage": null,
	  "trial_period_days": null,
	  "usage_type": "licensed"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/plans/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
