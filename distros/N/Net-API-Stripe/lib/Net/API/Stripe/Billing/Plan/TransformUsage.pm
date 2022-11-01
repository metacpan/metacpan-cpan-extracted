##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Plan/TransformUsage.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Plan::TransformUsage;
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

sub divide_by { return( shift->_set_get_scalar( 'divide_by', @_ ) ); }

sub round { return( shift->_set_get_scalar( 'round', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Plan::TransformUsage - A Stripe Plan Transform Usage Object

=head1 SYNOPSIS

    my $usage = $plan->transform_usage({
        divide_by => 2,
        round => 0,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Apply a transformation to the reported usage or set quantity before computing the billed price. Cannot be combined with tiers.

Called from method B<transform_usage> in L<Net::API::Stripe::Billing::Plan>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Plan::TransformUsage> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 divide_by integer

Divide usage by this number.

=head2 round string

After division, either round the result up or down.

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
