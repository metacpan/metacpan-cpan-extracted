##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Customer/TaxInfoVerification.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Customer::TaxInfoVerification;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub additional_document { return( shift->_set_get_object( 'additional_document', 'Net::API::Stripe::Connect::Account::Document', @_ ) ); }

sub details { return( shift->_set_get_scalar( 'details', @_ ) ); }

sub details_code { return( shift->_set_get_scalar( 'details_code', @_ ) ); }

sub document { return( shift->_set_get_object( 'document', 'Net::API::Stripe::Connect::Account::Document', @_ ) ); }

## Can be either pending, unavailable, unverified, or verified
sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub verified_address { return( shift->_set_get_scalar( 'verified_address', @_ ) ); }

sub verified_name { return( shift->_set_get_scalar( 'verified_name', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Customer::TaxInfoVerification - A Customer Tax Verification Object

=head1 SYNOPSIS

    my $tx_info = $stripe->customer->tax_info_verification({
        additional_document => $account_document_object,
        details => 'Provided identity information could not be verified',
        details_code => 'document_name_mismatch',
        document => $account_document_object,
        status => 'pending',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is instantiated by method B<tax_info_verification> in module B<Net::API::Stripe::Customer>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Customer::TaxInfoVerification> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<additional_document> hash

A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.

This is a L<Net::API::Stripe::Connect::Account::Document> object.

=item B<details> string

A user-displayable string describing the verification state for the person. For example, this may say “Provided identity information could not be verified”.

=item B<details_code> string

One of document_address_mismatch, document_dob_mismatch, document_duplicate_type, document_id_number_mismatch, document_name_mismatch, document_nationality_mismatch, failed_keyed_identity, or failed_other. A machine-readable code specifying the verification state for the person.

=item B<document> hash

An identifying document for the person, either a passport or local ID card.

This is a L<Net::API::Stripe::Connect::Account::Document> object.

=item B<status> string

Verification status, one of pending, unavailable, unverified, or verified.

=item B<verified_address> string

Verified address.

=item B<verified_name> string

Verified name.

=back

=head1 API SAMPLE

	{
	  "id": "txi_123456789",
	  "object": "tax_id",
	  "country": "DE",
	  "created": 123456789,
	  "customer": "cus_fake123456789",
	  "livemode": false,
	  "type": "eu_vat",
	  "value": "DE123456789",
	  "verification": {
		"status": "pending",
		"verified_address": null,
		"verified_name": null
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/customers/>, L<https://stripe.com/docs/api/persons/object#person_object-relationship>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
