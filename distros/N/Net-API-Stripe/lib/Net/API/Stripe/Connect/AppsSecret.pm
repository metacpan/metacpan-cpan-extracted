##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/AppsSecret.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::AppsSecret;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub payload { return( shift->_set_get_scalar( 'payload', @_ ) ); }

sub scope { return( shift->_set_get_class( 'scope',
{ type => { type => "scalar" }, user => { type => "scalar" } }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::AppsSecret - The Secret object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Secret Store is an API that allows Stripe Apps developers to securely persist secrets for use by UI Extensions and app backends.

The primary resource in Secret Store is a C<secret>. Other apps can't view secrets created by an app. Additionally, secrets are scoped to provide further permission control.

All Dashboard users and the app backend share C<account> scoped secrets. Use the C<account> scope for secrets that don't change per-user, like a third-party API key.

A C<user> scoped secret is accessible by the app backend and one specific Dashboard user. Use the C<user> scope for per-user secrets like per-user OAuth tokens, where different users might have different permissions.

Related guide: L<Store data between page reloads|https://stripe.com/docs/stripe-apps/store-auth-data-custom-objects>.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 deleted boolean

If true, indicates that this secret has been deleted

=head2 expires_at timestamp

The Unix timestamp for the expiry time of the secret, after which the secret deletes.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 name string

A name for the secret that's unique within the scope.

=head2 payload string

The plaintext secret value to be stored.

=head2 scope hash

Specifies the scoping of the secret. Requests originating from UI extensions can only access account-scoped secrets or secrets scoped to their own user.

It has the following properties:

=over 4

=item C<type> string

The secret scope type.

=item C<user> string

The user ID, if type is set to "user"

=back

=head1 API SAMPLE

[
   {
      "created" : "1662261085",
      "expires_at" : null,
      "id" : "appsecret_5110QzMIZ0005GiEH1m0419O8KAxCG",
      "livemode" : 0,
      "name" : "test-secret",
      "object" : "apps.secret",
      "scope" : {
         "type" : "account"
      }
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/secret_management>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
