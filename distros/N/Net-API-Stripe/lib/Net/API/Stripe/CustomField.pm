##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/CustomField.pm
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
package Net::API::Stripe::CustomField;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::CustomField - A Stripe Custom Field Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This defines the custom fields showing on an invoice and is referred to by Stripe as C<invoice_settings>

It is used by C<Net::API::Stripe::Billing::Invoice>, C<Net::API::Stripe::Customer::TaxIds>, and C<Net::API::Stripe::Customer>

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

=item B<name> string

The name of the custom field.

=item B<value> string

The value of the custom field.

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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
