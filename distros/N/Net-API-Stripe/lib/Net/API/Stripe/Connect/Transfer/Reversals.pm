##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Transfer/Reversals.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Transfer::Reversals;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::List );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

# Inherited
# sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

## Array of Net::API::Stripe::Connect::Transfer::Reversal
## sub data { return( shift->_set_get_object_array( 'data', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ) ); }

# Inherited
# sub has_more { return( shift->_set_get_scalar( 'has_more', @_ ) ); }

# Inherited
# sub total_count { return( shift->_set_get_scalar( 'total_count', @_ ) ); }

# Inherited
# sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Transfer::Reversals - A list of Transfer Reversal as Object

=head1 SYNOPSIS

    my $list = $stripe->reversals( 'list' ) || die( $stripe->error );
    while( my $rev = $list->next )
    {
        printf( <<EOT, $rev->amount->format_money( 0, '¥' ), $rev->currency, $rev->created->iso8601 );
    Amount: %s
    Currency: %s
    Created: %s
    EOT
    }

Would produce:

    Amount: ¥2,000
    Currency: jpy
    Created: 2020-04-06T06:00:00

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A list of reversals that have been applied to the transfer.

This module inherits from L<Net::API::Stripe::List> and overrides only the B<data> method.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Transfer::Reversals> object.

=head2 has_more boolean

True if this list has another page of items after this one that can be fetched.

=head2 url string

The URL where this list can be accessed.

=head1 API SAMPLE

    {
      "object": "list",
      "url": "/v1/transfers/tr_fake123456789/reversals",
      "has_more": false,
      "data": [
        {
          "id": "trr_fake123456789",
          "object": "transfer_reversal",
          "amount": 1100,
          "balance_transaction": "txn_fake123456789",
          "created": 1571480456,
          "currency": "jpy",
          "destination_payment_refund": null,
          "metadata": {},
          "source_refund": null,
          "transfer": "tr_fake123456789"
        },
        {...},
        {...}
      ]
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/transfer_reversals/list>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
