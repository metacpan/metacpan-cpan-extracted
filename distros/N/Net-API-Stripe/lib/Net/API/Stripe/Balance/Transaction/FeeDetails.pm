##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance/Transaction/FeeDetails.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Balance::Transaction::FeeDetails;
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

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub application { return( shift->_set_get_scalar( 'application', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

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

    v0.100.0

=head1 DESCRIPTION

This is called from within L<Net::API::Stripe::Transaction> from method B<fee_details>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Balance::Transaction::FeeDetails> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 amount integer

Amount of the fee, in cents.

=head2 application string

ID of the Connect application that earned the fee.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 type string

Type of the fee, one of: application_fee, stripe_fee or tax.

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
