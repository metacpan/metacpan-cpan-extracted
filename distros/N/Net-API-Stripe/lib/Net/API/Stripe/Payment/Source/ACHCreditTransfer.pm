##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/ACHCreditTransfer.pm
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
package Net::API::Stripe::Payment::Source::ACHCreditTransfer;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub account_number { shift->_set_get_scalar( 'account_number', @_ ); }

sub bank_name { shift->_set_get_scalar( 'bank_name', @_ ); }

sub fingerprint { shift->_set_get_scalar( 'fingerprint', @_ ); }

sub routing_number { shift->_set_get_scalar( 'routing_number', @_ ); }

sub swift_code { shift->_set_get_scalar( 'swift_code', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::ACHCreditTransfer - A Stripe ACH Credit Transfer Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This module contains a snapshot of the transaction specific details of the ach_credit_transfer payment method.

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

=item B<account_number> string

Account number to transfer funds to.

=item B<bank_name> string

Name of the bank associated with the routing number.

=item B<routing_number> string

Routing transit number for the bank account to transfer funds to.

=item B<swift_code> string

SWIFT code of the bank associated with the routing number.

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_methods/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
