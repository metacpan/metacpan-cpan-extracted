##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Verification.pm
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
package Net::API::Stripe::Connect::Account::Verification;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

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

=head1 VERSION

    0.1

=head1 DESCRIPTION

The Stripe API has changed considerably as of 2019-02-19. The original methods here were used previously in Stripe API as part of the account verification, but has been replaced by a C<Net::API::Stripe::Connect::Account::Requirements> module.

Instead, the new methods are used for person, or company verification, not account.

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

=item B<additional_document> hash

A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.

This is a C<Net::API::Stripe::Connect::Account::Document> object.

=item B<details> string

A user-displayable string describing the verification state for the person. For example, this may say “Provided identity information could not be verified”.

=item B<details_code> string

One of document_address_mismatch, document_dob_mismatch, document_duplicate_type, document_id_number_mismatch, document_name_mismatch, failed_keyed_identity, or failed_other. A machine-readable code specifying the verification state for the person.

=item B<document> hash

An identifying document for the person, either a passport or local ID card.

This is a C<Net::API::Stripe::Connect::Account::Document> object.

=item B<status> string

Verification status, one of pending, unavailable, unverified, or verified.

For persons, possible values are unverified, pending, or verified.

=item B<verified_address> string

Verified address.

=item B<verified_name> string

Verified name.

=back

=head1 OBSOLETE METHODS

=over 4

=item B<disabled_reason>

This has been replaced with the method B<past_due> in C<Net::API::Stripe::Connect::Account::Requirements>

=item B<due_by>

This has been replaced with the method B<current_deadline> in C<Net::API::Stripe::Connect::Account::Requirements>

=item B<fields_needed>

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/accounts/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

