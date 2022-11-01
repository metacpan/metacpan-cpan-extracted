##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/ACHDebit.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::ACHDebit;
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

sub account_holder_type { return( shift->_set_get_scalar( 'account_holder_type', @_ ) ); }

sub bank_name { return( shift->_set_get_scalar( 'bank_name', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub routing_number { return( shift->_set_get_scalar( 'routing_number', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::ACHDebit - A Stripe ACH Debit Object

=head1 SYNOPSIS

    my $ach_debit = $stripe->source->ach_debit({
        account_holder_type => 'company',
        bank_name => 'Big Buck, Corp',
        country => 'us',
        fingerprint => 'hskfhskjhajl',
        last4 => 1234,
        routing_number => undef,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This module contains a snapshot of the transaction specific details of the ach_debit payment method.

This is instantiated by method B<ach_debit> in module L<Net::API::Stripe::Payment::Method::Details> and L<Net::API::Stripe::Payment::Source>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::ACHDebit> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 account_holder_type string

Type of entity that holds the account. This can be either individual or company.

=head2 bank_name string

Name of the bank associated with the bank account.

=head2 country string

Two-letter ISO code representing the country the bank account is located in.

=head2 fingerprint string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=head2 last4 string

Last four digits of the bank account number.

=head2 routing_number string

Routing transit number of the bank account.

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_methods/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
