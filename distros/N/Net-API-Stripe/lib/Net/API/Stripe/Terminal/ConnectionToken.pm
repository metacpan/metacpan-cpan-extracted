##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/ConnectionToken.pm
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
## https://stripe.com/docs/api/terminal/connection_tokens/object
package Net::API::Stripe::Terminal::ConnectionToken;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub location { return( shift->_set_get_scalar( 'location', @_ ) ); }

sub secret { return( shift->_set_get_scalar( 'secret', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::ConnectionToken - A Stripe Connection Token Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A Connection Token is used by the Stripe Terminal SDK to connect to a reader.

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

=item B<object> string, value is "terminal.connection_token"

String representing the object’s type. Objects of the same type share the same value.

=item B<location> string

The id of the location that this connection token is scoped to.

=item B<secret> string

Your application should pass this token to the Stripe Terminal SDK.

=back

=head1 API SAMPLE

	{
	  "object": "terminal.connection_token",
	  "secret": "pst_test_RG4m9nG5DN9AsKcu0z2bn1J"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/terminal/connection_tokens>, L<https://stripe.com/docs/terminal/readers/fleet-management#create>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
