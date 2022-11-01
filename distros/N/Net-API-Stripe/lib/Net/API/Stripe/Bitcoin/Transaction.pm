##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Bitcoin/Transaction.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Bitcoin::Transaction;
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

sub bitcoin_amount { return( shift->_set_get_number( 'bitcoin_amount', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub receiver { return( shift->_set_get_scalar( 'receiver', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Bitcoin::Transaction - A Stripe Bitcoin Transaction Object

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A Bitcoin Transaction module.

As of 2019-11-01, this is an undocumented object in Stripe api documentation. It was found in L<https://stripe.com/docs/api/customers/object> under the I<sources> property.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Bitcoin::Transaction> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "bitcoin_transaction"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount positive integer

The amount of currency that the transaction was converted to in real-time.

=head2 bitcoin_amount positive integer

The amount of bitcoin contained in the transaction.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO code for the currency to which this transaction was converted.

=head2 receiver string

The receiver to which this transaction was sent.

=head1 API SAMPLE

    No API sample provided by Stripe yet.

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customers/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
