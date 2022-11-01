##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Transfer/Reversal.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/transfer_reversals
package Net::API::Stripe::Connect::Transfer::Reversal;
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

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub destination_payment_refund { return( shift->_set_get_scalar_or_object( 'destination_payment_refund', 'Net::API::Stripe::Refund', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub source_refund { return( shift->_set_get_scalar_or_object( 'source_refund', 'Net::API::Stripe::Refund', @_ ) ); }

sub transfer { return( shift->_set_get_scalar_or_object( 'transfer', 'Net::API::Stripe::Connect::Transfer', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Transfer::Reversal - A Stripe Transfer Reversal Object

=head1 SYNOPSIS

    my $rev = $stripe->transfer_reversal({
        amount => 2000,
        currency => 'jpy',
        destination_payment_refund => $refund_object,
        metadata => { transaction_id => 123 },
        transfer => $transfer_object,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Stripe Connect (L<https://stripe.com/docs/connect>) platforms can reverse transfers made to a connected account, either entirely or partially, and can also specify whether to refund any related application fees. Transfer reversals add to the platform's balance and subtract from the destination account's balance.

Reversing a transfer that was made for a destination charge (L<https://stripe.com/docs/connect/destination-charges>) is allowed only up to the amount of the charge. It is possible to reverse a transfer_group (L<https://stripe.com/docs/connect/charges-transfers#grouping-transactions>) transfer only if the destination account has enough balance to cover the reversal.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Transfer::Reversal> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.
object string, value is "transfer_reversal"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

Amount, in JPY.

=head2 balance_transaction string (expandable)

Balance transaction that describes the impact on your account balance. This is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 destination_payment_refund string (expandable)

Linked payment refund for the transfer reversal.

When expanded, this is a L<Net::API::Stripe::Refund> object.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 source_refund string (expandable)

ID of the refund responsible for the transfer reversal.

When expanded, this is a L<Net::API::Stripe::Refund> object.

=head2 transfer string (expandable)

ID of the transfer that was reversed.

When expanded, this is a L<Net::API::Stripe::Connect::Transfer>

=head1 API SAMPLE

    {
      "id": "trr_fake123456789",
      "object": "transfer_reversal",
      "amount": 1100,
      "balance_transaction": null,
      "created": 1571313252,
      "currency": "jpy",
      "destination_payment_refund": null,
      "metadata": {},
      "source_refund": null,
      "transfer": "tr_fake123456789"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/transfer_reversals>, L<https://stripe.com/docs/connect/charges-transfers#reversing-transfers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
