##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Financial/Connections/Session.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Financial::Connections::Session;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account_holder { return( shift->_set_get_object( 'account_holder', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub accounts { return( shift->_set_get_object( 'accounts', 'Net::API::Stripe::List', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub filters { return( shift->_set_get_class( 'filters',
{ countries => { type => "array" } }, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub permissions { return( shift->_set_get_array( 'permissions', @_ ) ); }

sub return_url { return( shift->_set_get_scalar( 'return_url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Financial::Connections::Session - The Session object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A Financial Connections Session is the secure way to programmatically launch the client-side Stripe.js modal that lets your users link their accounts.


=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 account_holder object

The account holder for whom accounts are collected in this session.

This is a L<Net::API::Stripe::Payment::Source> object.

=head2 accounts object

The accounts that were collected as part of this Session.

This is a L<Net::API::Stripe::List> object.

=head2 client_secret string

A value that will be passed to the client to launch the authentication flow.

=head2 filters hash

Filters applied to this session that restrict the kinds of accounts to collect.

It has the following properties:

=over 4

=item C<countries> string_array

List of countries from which to filter accounts.

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 permissions array

Permissions requested for accounts collected during this session.

=head2 return_url string

For webview integrations only. Upon completing OAuth login in the native browser, the user will be redirected to this URL to return to your app.

=head1 API SAMPLE

[
   {
      "accountholder" : {
         "account" : "acct_1KdUF8RhmIBPIfCO",
         "type" : "account"
      },
      "client_secret" : "fcsess_client_secret_PZri8EdhlStQTdnecntKdjnx",
      "filters" : {
         "countries" : [
            "US"
         ]
      },
      "id" : "fcsess_1LE8to2eZvKYlo2CeCL5ftCO",
      "linked_accounts" : {
         "data" : [],
         "has_more" : 0,
         "object" : "list",
         "url" : "/v1/linked_accounts"
      },
      "livemode" : 0,
      "object" : "link_account_session",
      "permissions" : [
         "ownership",
         "payment_method"
      ]
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/financial_connections/session>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
