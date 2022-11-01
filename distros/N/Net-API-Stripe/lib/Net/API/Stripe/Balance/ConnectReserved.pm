##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Balance/ConnectReserved.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Balance::ConnectReserved;
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

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub source_types { return( shift->_set_get_hash_as_object( 'source_types', 'Net::API::Stripe::Payment::Source::Types', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Balance::ConnectReserved - A Stripe Reserved Fund Object

=head1 SYNOPSIS

    my $reserved = $stripe->balance->connect_reserved({
        amount => '100000,
        currency => 'jpy',
        source_types => 
        {
            bank_account => 1000000,
            card => 0,
        },
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is called from L<Net::API::Stripe::Balance> by B<connect_reserved> method.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Balance::ConnectReserved> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 amount integer

Balance amount.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 source_types hash

Breakdown of balance by source types. This is a virtual L<Net::API::Stripe::Payment::Source::Types> module that contains the following properties:

=over 4

=item I<bank_account> integer

Amount for bank account.

=item I<card> integer

Amount for card.

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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
