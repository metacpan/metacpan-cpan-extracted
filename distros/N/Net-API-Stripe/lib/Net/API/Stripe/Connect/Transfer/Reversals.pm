##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Transfer/Reversals.pm
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
package Net::API::Stripe::Connect::Transfer::Reversals;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# Inherited
# sub object { shift->_set_get_scalar( 'object', @_ ); }

## Array of Net::API::Stripe::Connect::Transfer::Reversal
## sub data { shift->_set_get_object_array( 'data', 'Net::API::Stripe::Connect::Transfer::Reversal', @_ ); }

# Inherited
# sub has_more { shift->_set_get_scalar( 'has_more', @_ ); }

# Inherited
# sub total_count { shift->_set_get_scalar( 'total_count', @_ ); }

# Inherited
# sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Transfer::Reversals - A list of Transfer Reversal as Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A list of reversals that have been applied to the transfer.

This module inherits from C<Net::API::Stripe::List> and overrides only the B<data> method.

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

=item B<object> string, value is "list"

String representing the object’s type. Objects of the same type share the same value. Always has the value list.

=item B<data> array of hashes

Array of C<Net::API::Stripe::Connect::Transfer::Reversal> objects.

=item B<has_more> boolean

True if this list has another page of items after this one that can be fetched.

=item B<url> string

The URL where this list can be accessed.

=back

=head1 API SAMPLE

	{
	  "object": "list",
	  "url": "/v1/transfers/tr_1FVF3MCeyNCl6fY2ibhPTw7J/reversals",
	  "has_more": false,
	  "data": [
		{
		  "id": "trr_1FVF3MCeyNCl6fY2UM85yr0M",
		  "object": "transfer_reversal",
		  "amount": 1100,
		  "balance_transaction": "txn_1A3RPuCeyNCl6fY29RsjBA0b",
		  "created": 1571480456,
		  "currency": "jpy",
		  "destination_payment_refund": null,
		  "metadata": {},
		  "source_refund": null,
		  "transfer": "tr_1FVF3MCeyNCl6fY2ibhPTw7J"
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
