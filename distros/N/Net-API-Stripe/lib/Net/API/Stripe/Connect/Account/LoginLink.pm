##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/LoginLink.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
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
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::LoginLink - A Stripe Login Link Object

=head1 SYNOPSIS

    my $login_lnk = $stripe->login_link({
        url => 'https://example.com/login',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Login link module as documented on the Stripe Account section

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::LoginLink> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 object string, value is "login_link"

String representing the object’s type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 url string

The URL for the login link.

=head1 API SAMPLE

    {
      "object": "login_link",
      "created": 1571735987,
      "url": "https://connect.stripe.com/express/nnmcnbmzbcnm"
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
