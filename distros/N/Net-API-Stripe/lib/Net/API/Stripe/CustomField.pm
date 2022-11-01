##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/CustomField.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::CustomField;
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

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::CustomField - A Stripe Custom Field Object

=head1 SYNOPSIS

    my $customs = $stripe->invoice->custom_fields([
        {
        name => 'some name',
        value => 'some value,
        },
        {
        name => 'other name',
        value => 'other value,
        },
    ]);

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This defines the custom fields showing on an invoice and is referred to by Stripe as C<invoice_settings>

It is used by L<Net::API::Stripe::Billing::Invoice>, L<Net::API::Stripe::Customer::TaxIds>, and L<Net::API::Stripe::Customer>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::CustomField> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 name string

The name of the custom field.

=head2 value string

The value of the custom field.

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
