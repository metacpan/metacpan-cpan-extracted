##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Installment.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Installment;
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

sub available_plans { return( shift->_set_get_object_array( 'available_plans', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub enabled { return( shift->_set_get_boolean( 'enabled', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Installment - A Stripe Instalment Payment Object

=head1 SYNOPSIS

    my $inst = $stripe->card->installments({
        plan => $plan_object,
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Installment details for this payment (Mexico only).

For more information, see the installments integration guide (L<https://stripe.com/docs/payments/installments>).

This is instantiated by method B<installments> in module L<Net::API::Stripe::Connect::ExternalAccount::Card>

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Payment::Installment> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 available_plans array of objects

Installment plans that may be selected for this PaymentIntent.

This is a L<Net::API::Stripe::Billing::Plan> object.

=head2 enabled boolean

Whether Installments are enabled for this PaymentIntent.

=head2 plan hash

This is a C<Net::API::Stripe::Billing::Plan;> object who only 3 following properties are used:

=over 4

=item I<count> integer

For fixed_count installment plans, this is the number of installment payments your customer will make to their credit card.

=item I<interval> string

For fixed_count installment plans, this is the interval between installment payments your customer will make to their credit card.

=item I<type> string

Type of installment plan, one of fixed_count.

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/payments/installments>

L<Payment intent, instalment property|https://stripe.com/docs/api/payment_intents/object#payment_intent_object-payment_method_options-card-installments>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
