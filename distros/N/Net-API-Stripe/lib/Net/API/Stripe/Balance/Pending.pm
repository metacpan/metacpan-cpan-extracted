##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance/Pending.pm
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
package Net::API::Stripe::Balance::Pending;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub source_types { return( shift->_set_get_hash_as_object( 'source_types', 'Net::API::Stripe::Payment::Source::Types', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance::Pending - A Stripe Pending Fund Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

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

=item B<amount> integer

Balance amount.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<source_types> hash

Breakdown of balance by source types. This is a virtual C<Net::API::Stripe::Payment::Source::Types> module that contains the following properties:

=over 8

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

=back

=back

=head1 API SAMPLE

	{
	  "object": "balance",
	  "available": [
		{
		  "amount": 7712,
		  "currency": "jpy",
		  "source_types": {
			"card": 7712
		  }
		}
	  ],
	  "connect_reserved": [
		{
		  "amount": 0,
		  "currency": "jpy"
		}
	  ],
	  "livemode": false,
	  "pending": [
		{
		  "amount": 0,
		  "currency": "jpy",
		  "source_types": {
			"card": 0
		  }
		}
	  ]
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
