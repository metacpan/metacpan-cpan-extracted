##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Verification.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Verification;
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

sub additional_document { return( shift->_set_get_object( 'additional_document', 'Net::API::Stripe::Connect::Account::Document', @_ ) ); }

sub details { return( shift->_set_get_scalar( 'details', @_ ) ); }

sub details_code { return( shift->_set_get_scalar( 'details_code', @_ ) ); }

sub document { return( shift->_set_get_object( 'document', 'Net::API::Stripe::Connect::Account::Document', @_ ) ); }

## Old methods
sub disabled_reason { return( shift->_set_get_scalar( 'disabled_reason', @_ ) ); }

sub due_by { return( shift->_set_get_datetime( 'due_by', @_ ) ); }

sub fields_needed { return( shift->_set_get_array( 'fields_needed', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub verified_address { return( shift->_set_get_scalar( 'verified_address', @_ ) ); }

sub verified_name { return( shift->_set_get_scalar( 'verified_name', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Verification - A Stripe Account Verification Object

=head1 SYNOPSIS

    my $check = $stripe->account->verification({
        additional_document => $document_object,
        details => 'Provided identity information could not be verified',
        details_code => 'document_name_mismatch',
        document => $document_object,
        # For tax ids verification
        # verified_address => '1-2-3 Kudan-minami, Chiyoda-ku, Tokyo 123-4567',
        # verified_name => 'John Doe',
        status => 'unverified',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

The Stripe API has changed considerably as of 2019-02-19. The original methods here were used previously in Stripe API as part of the account verification, but has been replaced by a L<Net::API::Stripe::Connect::Account::Requirements> module.

Instead, the new methods are used for person, or company verification, not account.

This is instantiated by method B<tos_acceptance> from modules L<Net::API::Stripe::Connect::Account>, L<Net::API::Stripe::Connect::Account::Company>, L<Net::API::Stripe::Connect::Person>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Verification> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 additional_document hash

A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.

This is a L<Net::API::Stripe::Connect::Account::Document> object.

=head2 details string

A user-displayable string describing the verification state for the person. For example, this may say “Provided identity information could not be verified”.

=head2 details_code string

One of document_address_mismatch, document_dob_mismatch, document_duplicate_type, document_id_number_mismatch, document_name_mismatch, failed_keyed_identity, or failed_other. A machine-readable code specifying the verification state for the person.

=head2 document hash

An identifying document for the person, either a passport or local ID card.

This is a L<Net::API::Stripe::Connect::Account::Document> object.

=head2 status string

Verification status, one of pending, unavailable, unverified, or verified.

For persons, possible values are unverified, pending, or verified.

=head2 verified_address string

Verified address.

=head2 verified_name string

Verified name.

=head1 OBSOLETE METHODS

=head2 disabled_reason

This has been replaced with the method B<past_due> in L<Net::API::Stripe::Connect::Account::Requirements>

=head2 due_by

This has been replaced with the method B<current_deadline> in L<Net::API::Stripe::Connect::Account::Requirements>

=head2 fields_needed

Not documented

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/accounts/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

