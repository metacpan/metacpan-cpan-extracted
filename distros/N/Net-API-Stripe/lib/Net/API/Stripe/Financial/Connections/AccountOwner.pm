##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Financial/Connections/AccountOwner.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Financial::Connections::AccountOwner;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub ownership { return( shift->_set_get_scalar( 'ownership', @_ ) ); }

sub phone { return( shift->_set_get_scalar( 'phone', @_ ) ); }

sub raw_address { return( shift->_set_get_scalar( 'raw_address', @_ ) ); }

sub refreshed_at { return( shift->_set_get_datetime( 'refreshed_at', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Financial::Connections::AccountOwner - The Account Owner object

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

=head2 email string

The email address of the owner.

=head2 name string

The full name of the owner.

=head2 ownership string

The ownership object that this owner belongs to.

=head2 phone string

The raw phone number of the owner.

=head2 raw_address string

The raw physical address of the owner.

=head2 refreshed_at timestamp

The timestamp of the refresh that updated this owner.

=head1 API SAMPLE

[
   {
      "email" : "nobody+janesmith@stripe.com",
      "id" : "fcaown_1Le9F42eZvKYlo2CWabVv9DR",
      "name" : "Jane Smith",
      "object" : "linked_account_owner",
      "ownership" : "fcaowns_1Le9F42eZvKYlo2CqGhk2pIp",
      "phone" : "+1 555-555-5555",
      "raw_address" : "123 Main Street, Everytown USA",
      "refreshed_at" : null
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
