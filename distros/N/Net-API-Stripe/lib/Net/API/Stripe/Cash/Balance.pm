##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Cash/Balance.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/07/06
## Modified 2022/07/06
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Cash::Balance;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub available { return( shift->_set_get_hash_as_mix_object( 'available', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub settings
{
    return( shift->_set_get_class( 'settings',
    {
    reconciliation_mode => { type => 'scalar' },
    }, @_ ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Cash::Balance - Stripe API

=head1 SYNOPSIS

    use Net::API::Stripe::Cash::Balance;
    my $this = Net::API::Stripe::Cash::Balance->new(
        object => 'cash_balance',
        available =>
            {
            jpy => 10000,
            },
        customer => 'cu_abcdefgh1234567890',
        livemode => 0,
        settings =>
        {
        reconciliation_mode => 'automatic'
    ) || die( Net::API::Stripe::Cash::Balance->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represent a Stripe customer cash balance.

=head1 METHODS

=head2 object

String, value is "cash_balance"

String representing the object’s type. Objects of the same type share the same value.

=head2 available

A hash of all cash balances available to this customer. You cannot delete a customer with any cash balances, even if the balance is 0.

=head2 customer

String

The ID of the customer whose cash balance this object represents.

=head2 livemode

Boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 settings

Hash

The customer’s default cash balance settings.

=over 4

=item * C<reconciliation_mode> string

=back

The configuration for how funds that land in the customer cash balance are reconciled.

=head1 API SAMPLE

    {
      "object": "cash_balance",
      "available": {
        "jpy": 10000
      },
      "customer": "cu_1A3RPuCeyNCl6fY2YeKa3wSH",
      "livemode": false,
      "settings": {
        "reconciliation_mode": "automatic"
      }
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/cash_balance/object>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
