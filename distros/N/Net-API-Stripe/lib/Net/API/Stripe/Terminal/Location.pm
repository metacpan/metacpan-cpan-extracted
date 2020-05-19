##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/Location.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/terminal/locations
package Net::API::Stripe::Terminal::Location;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub address { shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ); }

sub display_name { shift->_set_get_scalar( 'display_name', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::Location - A Strip Terminal Reader Location Object

=head1 SYNOPSIS

    my $loc = $stripe->location({
        address => $address_object,
        display_name => 'Tokyo central',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A Location represents a grouping of readers.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Terminal::Location> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "terminal.location"

String representing the object’s type. Objects of the same type share the same value.

=item B<address> hash

The full address of the location.

This is a L<Net::API::Stripe::Address> object.

=item B<display_name> string

The display name of the location.

=back

=head1 API SAMPLE

	{
	  "id": "tml_fake123456789",
	  "object": "terminal.location",
	  "address": {
		"city": "Anytown",
		"country": "US",
		"line1": "1234 Main street",
		"line2": null,
		"postal_code": "123456",
		"state": null
	  },
	  "display_name": "My First Store"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/terminal/locations>, L<https://stripe.com/docs/terminal/readers/fleet-management#create>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
