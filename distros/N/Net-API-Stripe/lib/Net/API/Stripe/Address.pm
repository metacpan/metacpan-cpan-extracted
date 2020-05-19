##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Address.pm
## Version v0.100.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Address;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub city { shift->_set_get_scalar( 'city', @_ ); }

sub country { shift->_set_get_scalar( 'country', @_ ); }

sub line1 { shift->_set_get_scalar( 'line1', @_ ); }

sub line2 { shift->_set_get_scalar( 'line2', @_ ); }

sub postal_code { shift->_set_get_scalar( 'postal_code', @_ ); }

sub state { shift->_set_get_scalar( 'state', @_ ); }

sub town { return( shift->_set_get_scalar( 'town', @_ ) ); }

*zip_code = \&postal_code;

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Address - A Stripe Address Object

=head1 SYNOPSIS

   my $addr = $stripe->address({
       line1 => '1-2-3 Kudan-minami, Chiyoda-ku',
       line2 => 'Big Bldg 12F',
       city => 'Tokyo',
       postal_code => '123-4567',
       country => 'jp',
   });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is an Address module used everywhere in Stripe API.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Address> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<city> string

City/District/Suburb/Town/Village.

=item B<country> string

2-letter country code.

=item B<line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<postal_code> string

ZIP or postal code.

=item B<state> string

State/County/Province/Region.

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
