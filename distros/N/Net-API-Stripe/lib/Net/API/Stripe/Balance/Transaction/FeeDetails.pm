##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance/Transaction/FeeDetails.pm
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
package Net::API::Stripe::Balance::Transaction::FeeDetails;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub application { shift->_set_get_scalar( 'application', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance::Transaction::FeeDetails - A Stripe Fee Details Objects

=head1 SYNOPSIS

	my $fee_details = Net::API::Stripe::Balance::Transaction::FeeDetails->new({
	    amount => 2000,
	    currency => 'eur',
	    description => 'Some transaction',
	    type => 'application_fee',
	});

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is called from within L<Net::API::Stripe::Transaction> from method B<fee_details>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Balance::Transaction::FeeDetails> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<amount> integer

Amount of the fee, in cents.

=item B<application> string

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<type> string

Type of the fee, one of: application_fee, stripe_fee or tax.

=back

=head1 API SAMPLE

	{
	  "id": "txn_fake124567890",
	  "object": "balance_transaction",
	  "amount": 8000,
	  "available_on": 1571443200,
	  "created": 1571128827,
	  "currency": "jpy",
	  "description": "Invoice 123456-0039",
	  "exchange_rate": null,
	  "fee": 288,
	  "fee_details": [
		{
		  "amount": 288,
		  "application": null,
		  "currency": "jpy",
		  "description": "Stripe processing fees",
		  "type": "stripe_fee"
		}
	  ],
	  "net": 7712,
	  "source": "ch_fake124567890",
	  "status": "pending",
	  "type": "charge"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
