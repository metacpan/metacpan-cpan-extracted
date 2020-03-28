##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/LoginLink.pm
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
## https://stripe.com/docs/api/account/login_link
# (
#   "object": "login_link",
#   "created": 1540170121,
#   "url": "https://connect.stripe.com/express/JC0IkhqjOUma"
# )
package Net::API::Stripe::Connect::Account::LoginLink;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::LoginLink - A Stripe Login Link Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Login link module as documented on the Stripe Account section

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

=item B<object> string, value is "login_link"

String representing the object’s type. Objects of the same type share the same value.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<url> string

The URL for the login link.

=back

=head1 API SAMPLE

	{
	  "object": "login_link",
	  "created": 1571735987,
	  "url": "https://connect.stripe.com/express/lxOWU12Ds0Sa"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/account/login_link>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
