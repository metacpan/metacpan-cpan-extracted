##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/Types.pm
## Version v0.1.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/11/15
## Modified 2020/11/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::Types;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub bank_account { return( shift->_set_get_number( 'bank_account', @_ ) ); }

sub card { return( shift->_set_get_number( 'card', @_ ) ); }

sub fpx { return( shift->_set_get_number( 'fpx', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::Types - Payment Source Types

=head1 SYNOPSIS

    my $types = $stripe->payment->source->types({
        bank_account => 1000000,
        card => 1000,
        fpx => 0,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is called from L<Net::API::Stripe::Balance::ConnectReserved> and L<Net::API::Stripe::Balance::Pending>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::Types> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 bank_account integer

Amount for bank account.

=head2 card integer

Amount for card.

=head2 fpx integer

Amount for FPX.

=head1 API SAMPLE

    {
      "object": "balance",
      "available": [
        {
          "amount": 0,
          "currency": "jpy",
          "source_types": {
            "card": 0
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
          "amount": 7712,
          "currency": "jpy",
          "source_types": {
            "card": 7712
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

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
