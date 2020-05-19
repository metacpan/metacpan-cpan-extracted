##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/GeneratedFrom.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Payment::GeneratedFrom;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub charge { return( shift->_set_get_scalar( 'charge', @_ ) ); }

sub payment_method_details { return( shift->_set_get_object( 'payment_method_details', 'Net::API::Stripe::Payment::Method::Details', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::GeneratedFrom - A Stripe Payment Method Origin Object

=head1 SYNOPSIS

    my $form = $stripe->card->generated_from({
        charge => 'ch_fake1234567890',
        payment_method_details => $payment_method_details_object,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Details of the original PaymentMethod that created this object.

This is used in L<Net::API::Stripe::Connect::ExternalAccount::Card> itself used in L<Net::API::Stripe::Payment::Method>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::GeneratedFrom> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<charge> string

The charge that created this object.

=item B<payment_method_details> hash

Transaction-specific details of the payment method used in the payment.

This is a L<Net::API::Stripe::Payment::Method::Details> object.

=back

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
