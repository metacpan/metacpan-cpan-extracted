##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/Document.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::Document;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub address { return( shift->_set_get_object( 'address', 'Net::API::Stripe::Address', @_ ) ); }

sub back { return( shift->_set_get_scalar_or_object( 'back', 'Net::API::Stripe::File', @_ ) ); }

sub details { return( shift->_set_get_scalar( 'details', @_ ) ); }

sub details_code { return( shift->_set_get_scalar( 'details_code', @_ ) ); }

sub dob { return( shift->_set_get_class( 'dob',
{
  day   => { type => "number" },
  month => { type => "number" },
  year  => { type => "number" },
}, @_ ) ); }

sub expiration_date { return( shift->_set_get_class( 'expiration_date',
{
  day   => { type => "number" },
  month => { type => "number" },
  year  => { type => "number" },
}, @_ ) ); }

sub files { return( shift->_set_get_array( 'files', @_ ) ); }

sub first_name { return( shift->_set_get_scalar( 'first_name', @_ ) ); }

sub front { return( shift->_set_get_scalar_or_object( 'front', 'Net::API::Stripe::File', @_ ) ); }

sub issued_date { return( shift->_set_get_class( 'issued_date',
{
  day   => { type => "number" },
  month => { type => "number" },
  year  => { type => "number" },
}, @_ ) ); }

sub issuing_country { return( shift->_set_get_scalar( 'issuing_country', @_ ) ); }

sub last_name { return( shift->_set_get_scalar( 'last_name', @_ ) ); }

sub number { return( shift->_set_get_scalar( 'number', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::Document - An interface to Stripe API

=head1 SYNOPSIS

    my $doc = $stripe->account->verification->document({
        back => '/some/file/path/scan_back.jpg',
        details => 'Low resolution jpeg',
        # Set by Stripe
        # details_code => 'document_not_readable',
        front => '/some/file/path/scan_front.jpg',
    });

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.

Tis is called from method B<document> in module L<Net::API::Stripe::Connect::Account::Verification>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::Account::Document> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 address object

Address as it appears in the document.

This is a L<Net::API::Stripe::Address> object.

=head2 back string (expandable)

The back of an ID returned by a file upload with a purpose value of identity_document.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 details string

A user-displayable string describing the verification state of this document. For example, if a document is uploaded and the picture is too fuzzy, this may say “Identity document is too unclear to read”.

=head2 details_code string

One of document_corrupt, document_country_not_supported, document_expired, document_failed_copy, document_failed_other, document_failed_test_mode, document_fraudulent, document_failed_greyscale, document_incomplete, document_invalid, document_manipulated, document_missing_back, document_missing_front, document_not_readable, document_not_uploaded, document_photo_mismatch, document_too_large, or document_type_not_supported. A machine-readable code specifying the verification state for this document.

=head2 dob hash

Date of birth as it appears in the document.

It has the following properties:

=over 4

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.

=back

=head2 expiration_date hash

Expiration date of the document.

It has the following properties:

=over 4

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.

=back

=head2 files string_array

Array of L<File|https://stripe.com/docs/api/files> ids containing images for this document.

=head2 first_name string

First name as it appears in the document.

=head2 front string (expandable)

The front of an ID returned by a file upload with a purpose value of identity_document.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 issued_date hash

Issued date of the document.

It has the following properties:

=over 4

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.

=back

=head2 issuing_country string

Issuing country of the document.

=head2 last_name string

Last name as it appears in the document.

=head2 number string

Document ID number.

=head2 status string

Status of this C<document> check.

=head2 type string

Type of the document.

=head1 API SAMPLE

    {
      "id": "person_fake123456789",
      "object": "person",
      "account": "acct_fake123456789",
      "created": 1580075612,
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
