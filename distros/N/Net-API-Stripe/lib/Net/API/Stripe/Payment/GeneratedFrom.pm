##----------------------------------------------------------------------------
## Stripe API - ~/usr/local/src/perl/Net-API-Stripe/lib/Net/API/Stripe/Payment/GeneratedFrom.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::GeneratedFrom;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub charge { return( shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ) ); }

sub payment_method_details { return( shift->_set_get_object( 'payment_method_details', 'Net::API::Stripe::Payment::Method::Details', @_ ) ); }

sub setup_attempt { return( shift->_set_get_scalar_or_object( 'setup_attempt', 'Net::API::Stripe::SetupAttempt', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::GeneratedFrom - A Stripe Payment Method Origin Object

=head1 SYNOPSIS

    my $form = $stripe->card->generated_from({
        ## Net::API::Stripe::Charge
        charge => 'ch_fake1234567890',
        ## Net::API::Stripe::Payment::Method::Details
        payment_method_details => $payment_method_details_object,
        ## Net::API::Stripe::SetupAttempt
        setup_attempt => $setup_attempt_object,
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Details of the original PaymentMethod that created this object.

This is used in L<Net::API::Stripe::Connect::ExternalAccount::Card> itself used in L<Net::API::Stripe::Payment::Method>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::GeneratedFrom> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 charge string expandable

The charge that created this object.

This is a L<Net::API::Stripe::Charge> object.

=head2 payment_method_details hash

Transaction-specific details of the payment method used in the payment.

This is a L<Net::API::Stripe::Payment::Method::Details> object.

=head2 setup_attempt string expandable

The ID of the SetupAttempt that generated this PaymentMethod, if any.

This is a L<Net::API::Stripe::SetupAttempt> object.

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
