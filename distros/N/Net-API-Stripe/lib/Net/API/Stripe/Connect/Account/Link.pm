##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Link.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Link;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ) };

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ) };

sub url { return( shift->_set_get_uri( 'url', @_ ) ) };

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Link - A Stripe Account Link Object

=head1 SYNOPSIS

    my $lnk = $stripe->account_link({
        expires_at => '2020-06-01',
        url => 'https://example.com/some/file.pdf',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Account Links are the means by which a Connect platform grants a connected account permission to access Stripe-hosted applications, such as Connect Onboarding.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Link> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<object> string, value is "account_link"

String representing the object’s type. Objects of the same type share the same value.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<expires_at> timestamp

The timestamp at which this account link will expire.

=item B<url> string

The URL for the account link.

=back

=head1 API SAMPLE

	{
	  "object": "account_link",
	  "created": 1571480455,
	  "expires_at": 1571480755,
	  "url": "https://connect.stripe.com/setup/c/mbmnjccbnmcbnmcb"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/account_links>, L<https://stripe.com/docs/connect/connect-onboarding>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
