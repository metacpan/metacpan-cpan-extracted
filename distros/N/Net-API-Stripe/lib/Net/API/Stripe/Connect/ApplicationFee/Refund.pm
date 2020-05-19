##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/ApplicationFee/Refund.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/fee_refunds/object
package Net::API::Stripe::Connect::ApplicationFee::Refund;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub fee { shift->_set_get_scalar_or_object( 'fee', 'Net::API::Stripe::Connect::ApplicationFee', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::ApplicationFee::Refund - A Stripe Application Fee Refund Object

=head1 SYNOPSIS

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Application Fee Refund objects allow you to refund an application fee that has previously been created but not yet refunded. Funds will be refunded to the Stripe account from which the fee was originally collected.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::ApplicationFee::Refund> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "fee_refund"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

Amount, in JPY.

=item B<balance_transaction> string (expandable)

Balance transaction that describes the impact on your account balance.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

This is a C<DateTime> object.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<fee> string (expandable)

ID of the application fee that was refunded.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=back

=head1 API SAMPLE

	{
	  "id": "fr_fake123456789",
	  "object": "fee_refund",
	  "amount": 100,
	  "balance_transaction": null,
	  "created": 1571480455,
	  "currency": "jpy",
	  "fee": "fee_fake123456789",
	  "metadata": {}
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/fee_refunds>, L<https://stripe.com/docs/connect/destination-charges#refunding-app-fee>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
