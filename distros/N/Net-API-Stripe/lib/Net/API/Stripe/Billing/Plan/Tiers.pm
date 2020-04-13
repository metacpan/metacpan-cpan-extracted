##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Plan/Tiers.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Plan::Tiers;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub flat_amount { return( shift->_set_get_number( 'flat_amount', @_ ) ); }

sub flat_amount_decimal { return( shift->_set_get_number( 'flat_amount_decimal', @_ ) ); }

sub unit_amount { shift->_set_get_number( 'unit_amount', @_ ); }

sub unit_amount_decimal { return( shift->_set_get_number( 'unit_amount_decimal', @_ ) ); }

sub up_to { shift->_set_get_number( 'up_to', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Plan::Tiers - A Stripe Plan Tiers Object

=head1 SYNOPSIS

    my $tiers = $plan->tiers({
        flat_amount => 2000,
        flat_amount_decimal => 2000,
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

Each element represents a pricing tier. This parameter requires billing_scheme to be set to tiered. See also the documentation for billing_scheme.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Plan::Tiers> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<flat_amount> integer

Price for the entire tier. This is a L<AI::API::Stripe::Number> object.

=item B<flat_amount_decimal> decimal string

Same as flat_amount, but contains a decimal value with at most 12 decimal places.

This is a L<AI::API::Stripe::Number> object.
 
=item B<unit_amount> integer

Per unit price for units relevant to the tier. This is a L<AI::API::Stripe::Number> object.

=item B<unit_amount_decimal> decimal string

Same as unit_amount, but contains a decimal value with at most 12 decimal places. This is a L<AI::API::Stripe::Number> object.

=item B<up_to> integer

Up to and including to this quantity will be contained in the tier. This is a L<AI::API::Stripe::Number> object.

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
	  "product": "prod_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
