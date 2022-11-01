##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source/ACHCreditTransfer.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Source::ACHCreditTransfer;
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

sub account_number { return( shift->_set_get_scalar( 'account_number', @_ ) ); }

sub bank_name { return( shift->_set_get_scalar( 'bank_name', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub routing_number { return( shift->_set_get_scalar( 'routing_number', @_ ) ); }

sub swift_code { return( shift->_set_get_scalar( 'swift_code', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source::ACHCreditTransfer - A Stripe ACH Credit Transfer Object

=head1 SYNOPSIS

    my $ach = $stripe->source->account_number({
        account_number => 1234567890,
        bank_name => 'Big Buck, Corp',
        fingerprint => 'hskfhskjhajl',
        routing_number => undef,
        swift_code => 'BIGBKS01',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This module contains a snapshot of the transaction specific details of the ach_credit_transfer payment method.

This is instantiated by method B<ach_credit_transfer> in module L<Net::API::Stripe::Payment::Method::Details> and L<Net::API::Stripe::Payment::Source>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source::ACHCreditTransfer> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 account_number string

Account number to transfer funds to.

=head2 bank_name string

Name of the bank associated with the routing number.

=head2 routing_number string

Routing transit number for the bank account to transfer funds to.

=head2 swift_code string

SWIFT code of the bank associated with the routing number.

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
