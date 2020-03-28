##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/ACHDebit.pm
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
package Net::API::Stripe::Payment::Source::ACHDebit;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub account_holder_type { return( shift->_set_get_scalar( 'account_holder_type', @_ ) ); }

sub bank_name { shift->_set_get_scalar( 'bank_name', @_ ); }

sub country { shift->_set_get_scalar( 'country', @_ ); }

sub fingerprint { shift->_set_get_scalar( 'fingerprint', @_ ); }

sub last4 { shift->_set_get_scalar( 'last4', @_ ); }

sub routing_number { shift->_set_get_scalar( 'routing_number', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::ACHDebit - A Stripe ACH Debit Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This module contains a snapshot of the transaction specific details of the ach_debit payment method.

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

=item B<account_holder_type> string

Type of entity that holds the account. This can be either individual or company.

=item B<bank_name> string

Name of the bank associated with the bank account.

=item B<country> string

Two-letter ISO code representing the country the bank account is located in.

=item B<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item B<last4> string

Last four digits of the bank account number.

=item B<routing_number> string

Routing transit number of the bank account.

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
