##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Card/AuthorizationsControl/SpendingLimit.pm
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
package Net::API::Stripe::Issuing::Card::AuthorizationsControl::SpendingLimit;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub categories { return( shift->_set_get_array( 'categories', @_ ) ); }

sub interval { return( shift->_set_get_scalar( 'interval', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Card::AuthorizationsControl::SpendingLimit - A Stripe Card Spending Limit Object

=head1 SYNOPSIS

    my $limit = $stripe->card_holder->authorization_controls->spending_limits([
        {
        amount => 2000000,
        categories => '',
        interval => 'monthly',
        },
        {
        amount => 200000,
        categories => '',
        interval => 'weekly',
        },
    ]);

=head1 VERSION

    0.1

=head1 DESCRIPTION

Limit the spending with rules based on time intervals and categories.

This is instantiated by method B<spending_limits> in module L<Net::API::Stripe::Issuing::Card::Holder>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Card::AuthorizationsControl::SpendingLimit> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<amount> positive integer

Maximum amount allowed to spend per time interval.

=item B<categories> array

Array of strings containing categories on which to apply the spending limit. Leave this blank to limit all charges.

=item B<interval> string

The time interval with which to apply this spending limit towards. Allowed values are per_authorization, daily, weekly, monthly, yearly, or all_time.

=back

=head1 API SAMPLE

	{
	  "id": "ich_fake123456789",
	  "object": "issuing.cardholder",
	  "authorization_controls": {
		"allowed_categories": [],
		"blocked_categories": [],
		"spending_limits": [],
		"spending_limits_currency": null
	  },
	  "billing": {
		"address": {
		  "city": "Beverly Hills",
		  "country": "US",
		  "line1": "123 Fake St",
		  "line2": "Apt 3",
		  "postal_code": "90210",
		  "state": "CA"
		},
		"name": "Jenny Rosen"
	  },
	  "company": null,
	  "created": 1540111055,
	  "email": "jenny@example.com",
	  "individual": null,
	  "is_default": false,
	  "livemode": false,
	  "metadata": {},
	  "name": "Jenny Rosen",
	  "phone_number": "+18008675309",
	  "requirements": {
		"disabled_reason": null,
		"past_due": []
	  },
	  "status": "active",
	  "type": "individual"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/cardholders/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
