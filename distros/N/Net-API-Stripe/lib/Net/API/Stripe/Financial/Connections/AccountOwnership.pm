##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Financial/Connections/AccountOwnership.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Financial::Connections::AccountOwnership;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub owners { return( shift->_set_get_object( 'owners', 'Net::API::Stripe::List', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Financial::Connections::AccountOwnership - The Account Ownership object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Describes a snapshot of the owners of an account at a particular point in time.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 owners object

A paginated list of owners for this account.

This is a L<Net::API::Stripe::List> object.

=head1 API SAMPLE

[
   {
      "created" : "1662261086",
      "id" : "fcaowns_1Le9F42eZvKYlo2CfwkUGxZt",
      "object" : "linked_account_ownership",
      "owners" : {
         "data" : [],
         "has_more" : 0,
         "object" : "list",
         "url" : "/v1/linked_accounts/fca_1Le9F42eZvKYlo2CEjemQrlf/owners?ownership=fcaowns_1Le9F42eZvKYlo2CfwkUGxZt"
      }
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/financial_connections/ownership>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
