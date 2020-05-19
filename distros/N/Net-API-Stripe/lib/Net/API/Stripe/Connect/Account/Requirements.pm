##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Requirements.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Requirements;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

sub current_deadline { return( shift->_set_get_datetime( 'current_deadline', @_ ) ); }

sub currently_due { return( shift->_set_get_array( 'currently_due', @_ ) ); }

sub disabled_reason { return( shift->_set_get_scalar( 'disabled_reason', @_ ) ); }

# sub errors { return( shift->_set_get_array( 'errors', @_ ) ); }
sub errors
{
	return( shift->_set_get_class_array( 'errors',
	    {
	    code => { type => 'scalar' },
	    reason => { type => 'scalar' },
	    requirement => { type => 'scalar' },
	    })
	);
}

sub eventually_due { return( shift->_set_get_array( 'eventually_due', @_ ) ); }

sub past_due { return( shift->_set_get_array( 'past_due', @_ ) ); }

sub pending_verification { return( shift->_set_get_array( 'pending_verification', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Requirements - A Stripe Account Requirements Object

=head1 SYNOPSIS

    my $req = $stripe->person->requirements({
        current_deadline => '2020-05-01',
        errors => [
            {
            code => 'invalid_address_city_state_postal_code',
            reason => 'Some reason why this failed',
            requirement => 'some_field',
            }
        ],
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Information about the requirements for this person, including what information needs to be collected, and by when.

This is instantiated from method B<requirements> in modules L<Net::API::Stripe::Connect::Account>, L<Net::API::Stripe::Connect::Person> and L<Net::API::Stripe::Issuing::Card::Holder>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Requirements> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<current_deadline> timestamp

The date the fields in currently_due must be collected by to keep the capability enabled for the account.

This is a C<DateTime> object;

=item B<currently_due> array containing strings

Fields that need to be collected to keep the person’s account enabled. If not collected by the account’s current_deadline, these fields appear in past_due as well, and the account is disabled.

=item B<disabled_reason> string

If the capability is disabled, this string describes why. Possible values are requirement.fields_needed, pending.onboarding, pending.review, rejected_fraud, or rejected.other.

=item B<errors> array of hash

The fields that need to be collected again because validation or verification failed for some reason.

This is an array reference of virtual objects class L<Net::API::Stripe::Connect::Account::Requirements::Errors>

=over 4

=item I<code> The code for the type of error. Possible enum values

=over 8

=item I<invalid_address_city_state_postal_code>

The combination of the city, state, and postal code in the provided address could not be validated.

=item I<invalid_street_address>

The street name and/or number for the provided address could not be validated.

=item I<invalid_value_other>

An invalid value was provided for the related field. This is a general error code.

=item I<verification_document_address_mismatch>

The address on the document did not match the address on the account. Upload a document with a matching address or update the address on the account.

=item I<verification_document_address_missing>

The company address was missing on the document. Upload a document that includes the address.

=item I<verification_document_corrupt>

The uploaded file for the document was invalid or corrupt. Upload a new file of the document.

=item I<verification_document_country_not_supported>

The provided document was from an unsupported country.

=item I<verification_document_dob_mismatch>

The date of birth (DOB) on the document did not match the DOB on the account. Upload a document with a matching DOB or update the DOB on the account.

=item I<verification_document_duplicate_type>

The same type of document was used twice. Two unique types of documents are required for verification. Upload two different documents.

=item I<verification_document_expired>

The document could not be used for verification because it has expired. If it’s an identity document, its expiration date must be before the date the document was submitted. If it’s an address document, the issue date must be within the last six months.

=item I<verification_document_failed_copy>

The document could not be verified because it was detected as a copy (e.g., photo or scan). Upload the original document.

=item I<verification_document_failed_greyscale>

The document could not be used for verification because it was in greyscale. Upload a color copy of the document.

=item I<verification_document_failed_other>

The document could not be verified for an unknown reason. Ensure that the document follows the guidelines for document uploads.

=item I<verification_document_failed_test_mode>

A test data helper was supplied to simulate verification failure. Refer to the documentation for test file tokens.

=item I<verification_document_fraudulent>

The document was identified as altered or falsified.

=item I<verification_document_id_number_mismatch>

The company ID number on the account could not be verified. Correct any errors in the ID number field or upload a document that includes the ID number.

=item I<verification_document_id_number_missing>

The company ID number was missing on the document. Upload a document that includes the ID number.

=item I<verification_document_incomplete>

The document was cropped or missing important information. Upload a complete scan of the document.

=item I<verification_document_invalid>

The uploaded file was not one of the valid document types. Upload an acceptable ID document (e.g., ID card or passport).

=item I<verification_document_manipulated>

The document was identified as altered or falsified.

=item I<verification_document_missing_back>

The uploaded file was missing the back of the document. Upload a complete scan of the document.

=item I<verification_document_missing_front>

The uploaded file was missing the front of the document. Upload a complete scan of the document.

=item I<verification_document_name_mismatch>

The name on the document did not match the name on the account. Upload a document with a matching name or update the name on the account.

=item I<verification_document_name_missing>

The company name was missing on the document. Upload a document that includes the company name.

=item I<verification_document_nationality_mismatch>

The nationality on the document did not match the person’s stated nationality. Update the person’s stated nationality, or upload a document that matches it.

=item I<verification_document_not_readable>

The document could not be read. Ensure that the document follows the guidelines for document uploads.

=item I<verification_document_not_uploaded>

No document was uploaded. Upload the document again.

=item I<verification_document_photo_mismatch>

The document was identified as altered or falsified.

=item I<verification_document_too_large>

The uploaded file exceeded the 10 MB size limit. Resize the document and upload the new file.

=item I<verification_document_type_not_supported>

The provided document type was not accepted as proof of identity. Upload an acceptable ID document (e.g., ID card or passport).

=item I<verification_failed_address_match>

The address on the account could not be verified. Correct any errors in the address field or upload a document that includes the address.

=item I<verification_failed_business_iec_number>

The Importer Exporter Code (IEC) number could not be verified. Correct any errors in the company’s IEC number field. (India only)

=item I<verification_failed_document_match>

The document could not be verified. Upload a document that includes the company name, ID number, and address fields.

=item I<verification_failed_id_number_match>

The company ID number on the account could not be verified. Correct any errors in the ID number field or upload a document that includes the ID number.

=item I<verification_failed_keyed_identity>

The person’s keyed-in identity information could not be verified. Correct any errors or upload a document that matches the identity fields (e.g., name and date of birth) entered.

=item I<verification_failed_keyed_match>

The keyed-in information on the account could not be verified. Correct any errors in the company name, ID number, or address fields. You can also upload a document that includes those fields.

=item I<verification_failed_name_match>

The company name on the account could not be verified. Correct any errors in the company name field or upload a document that includes the company name.

=item I<verification_failed_other>

Verification failed for an unknown reason. Correct any errors and resubmit the required fields.

=back

=item I<reason>

=item I<requirement>

=back

=item B<eventually_due> array containing strings

Fields that need to be collected assuming all volume thresholds are reached. As fields are needed, they are moved to currently_due and the account’s current_deadline is set.

=item B<past_due> array containing strings

Fields that weren’t collected by the account’s current_deadline. These fields need to be collected to enable payouts for the person’s account.

=item B<pending_verification> array containing strings

Fields that may become required depending on the results of verification or review. An empty array unless an asynchronous verification is pending. If verification fails, the fields in this array become required and move to currently_due or past_due.

=back

=head1 API SAMPLE

	{
	  "id": "person_fake123456789",
	  "object": "person",
	  "account": "acct_fake123456789",
	  "created": 1571602397,
	  "dob": {
		"day": null,
		"month": null,
		"year": null
	  },
	  "first_name_kana": null,
	  "first_name_kanji": null,
	  "gender": null,
	  "last_name_kana": null,
	  "last_name_kanji": null,
	  "metadata": {},
	  "relationship": {
		"director": false,
		"executive": false,
		"owner": false,
		"percent_ownership": null,
		"representative": false,
		"title": null
	  },
	  "requirements": {
		"currently_due": [],
		"eventually_due": [],
		"past_due": [],
		"pending_verification": []
	  },
	  "verification": {
		"additional_document": {
		  "back": null,
		  "details": null,
		  "details_code": null,
		  "front": null
		},
		"details": null,
		"details_code": null,
		"document": {
		  "back": null,
		  "details": null,
		  "details_code": null,
		  "front": null
		},
		"status": "unverified"
	  }
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
