##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Installment.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::Installment;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan;', @_ ) ); }

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

    v0.100.0

=head1 DESCRIPTION

Installment details for this payment (Mexico only).

For more information, see the installments integration guide (L<https://stripe.com/docs/payments/installments>).

This is instantiated by method B<installments> in module L<Net::API::Stripe::Connect::ExternalAccount::Card>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Installment> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<plan> hash

This is a C<Net::API::Stripe::Billing::Plan;> object who only 3 following properties are used:

=over 8

=item B<count> integer

For fixed_count installment plans, this is the number of installment payments your customer will make to their credit card.

=item B<interval> string

For fixed_count installment plans, this is the interval between installment payments your customer will make to their credit card.

=item B<type> string

Type of installment plan, one of fixed_count.

=back

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/payments/installments>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
