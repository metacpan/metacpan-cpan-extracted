##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Invoice/Settings.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::Invoice::Settings;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub custom_fields { return( shift->_set_get_object_array( 'custom_fields', 'Net::API::Stripe::CustomField' ) ); }

sub default_payment_method { return( shift->_set_get_scalar_or_object( 'default_payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub footer { return( shift->_set_get_scalar( 'footer', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Invoice::Settings - A Stripe Invoice Setting Object

=head1 SYNOPSIS

    my $settings = $customer->invoice_settings({
        customer_fields => $custom_field_object,
        default_payment_method => 'pm_fake123456789',
        footer => 'Big Corp, Inc',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

This defines the invoice settings. It is instantiated from method B<invoice_settings> in L<Net::API::Stripe::Custome>

It is used by L<Net::API::Stripe::Billing::Invoice>, L<Net::API::Stripe::Customer::TaxIds>, and L<Net::API::Stripe::Customer>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Billing::Invoice::Settings> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<custom_fields> array of hashes

Default custom fields to be displayed on invoices for this customer. This is a L<Net::API::Stripe::CustomField> object

=item B<default_payment_method> string (expandable)

ID of the default payment method used for subscriptions and invoices for the customer.

When expanded, this is a L<Net::API::Stripe::Payment::Method> object.

=item B<footer> string

Default footer to be displayed on invoices for this customer.

=back

=head1 API SAMPLE

No sample data found yet

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/invoices/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
