##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Identity/VerificationReport.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Identity::VerificationReport;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub document { return( shift->_set_get_class( 'document',
{
  address => { package => "Net::API::Stripe::Address", type => "object" },
  dob => {
    definition => {
      day   => { type => "number" },
      month => { type => "number" },
      year  => { type => "number" },
    },
    type => "class",
  },
  error => {
    definition => { code => { type => "scalar" }, reason => { type => "scalar" } },
    type => "class",
  },
  expiration_date => {
    definition => {
      day   => { type => "number" },
      month => { type => "number" },
      year  => { type => "number" },
    },
    type => "class",
  },
  files => { type => "array" },
  first_name => { type => "scalar" },
  issued_date => {
    definition => {
      day   => { type => "number" },
      month => { type => "number" },
      year  => { type => "number" },
    },
    type => "class",
  },
  issuing_country => { type => "scalar" },
  last_name => { type => "scalar" },
  number => { type => "scalar" },
  status => { type => "scalar" },
  type => { type => "scalar" },
}, @_ ) ); }

sub id_number { return( shift->_set_get_class( 'id_number',
{
  dob => {
    definition => {
      day   => { type => "number" },
      month => { type => "number" },
      year  => { type => "number" },
    },
    type => "class",
  },
  error => {
    definition => { code => { type => "scalar" }, reason => { type => "scalar" } },
    type => "class",
  },
  first_name => { type => "scalar" },
  id_number => { type => "scalar" },
  id_number_type => { type => "scalar" },
  last_name => { type => "scalar" },
  status => { type => "scalar" },
}, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub options { return( shift->_set_get_class( 'options',
{
  document  => {
                 definition => {
                   allowed_types           => { type => "array" },
                   require_id_number       => { type => "boolean" },
                   require_live_capture    => { type => "boolean" },
                   require_matching_selfie => { type => "boolean" },
                 },
                 type => "class",
               },
  id_number => { type => "hash" },
}, @_ ) ); }

sub selfie { return( shift->_set_get_class( 'selfie',
{
  document => { type => "scalar" },
  error    => {
                definition => { code => { type => "scalar" }, reason => { type => "scalar" } },
                type => "class",
              },
  selfie   => { type => "scalar" },
  status   => { type => "scalar" },
}, @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub verification_session { return( shift->_set_get_scalar( 'verification_session', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Identity::VerificationReport - The VerificationReport object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A VerificationReport is the result of an attempt to collect and verify data from a user. The collection of verification checks performed is determined from the C<type> and C<options> parameters used. You can find the result of each verification check performed in the appropriate sub-resource: C<document>, C<id_number>, C<selfie>.

Each VerificationReport contains a copy of any data collected by the user as well as reference IDs which can be used to access collected images through the L<FileUpload|https://stripe.com/docs/api/files> API. To configure and create VerificationReports, use the L<VerificationSession|https://stripe.com/docs/api/identity/verification_sessions> API.

Related guides: L<Accessing verification results|https://stripe.com/docs/identity/verification-sessions#results>.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 document hash

Result of the document check for this report.

It has the following properties:

=over 4

=item C<address> hash

Address as it appears in the document.

When expanded, this is a L<Net::API::Stripe::Address> object.

=item C<dob> hash

Date of birth as it appears in the document.

=over 8

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.


=back

=item C<error> hash

Details on the verification error. Present when status is C<unverified>.

=over 8

=item C<code> string

A short machine-readable string giving the reason for the verification failure.

=item C<reason> string

A human-readable message giving the reason for the failure. These messages can be shown to your users.


=back

=item C<expiration_date> hash

Expiration date of the document.

=over 8

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.


=back

=item C<files> string_array

Array of L<File|https://stripe.com/docs/api/files> ids containing images for this document.

=item C<first_name> string

First name as it appears in the document.

=item C<issued_date> hash

Issued date of the document.

=over 8

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.


=back

=item C<issuing_country> string

Issuing country of the document.

=item C<last_name> string

Last name as it appears in the document.

=item C<number> string

Document ID number.

=item C<status> string

Status of this C<document> check.

=item C<type> string

Type of the document.

=back

=head2 id_number hash

Result of the id number check for this report.

It has the following properties:

=over 4

=item C<dob> hash

Date of birth.

=over 8

=item C<day> integer

Numerical day between 1 and 31.

=item C<month> integer

Numerical month between 1 and 12.

=item C<year> integer

The four-digit year.


=back

=item C<error> hash

Details on the verification error. Present when status is C<unverified>.

=over 8

=item C<code> string

A short machine-readable string giving the reason for the verification failure.

=item C<reason> string

A human-readable message giving the reason for the failure. These messages can be shown to your users.


=back

=item C<first_name> string

First name.

=item C<id_number> string

ID number.

=item C<id_number_type> string

Type of ID number.

=item C<last_name> string

Last name.

=item C<status> string

Status of this C<id_number> check.

=back

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 options hash

Configuration options for this report.

It has the following properties:

=over 4

=item C<document> hash

Configuration options to apply to the C<document> check.

=over 8

=item C<allowed_types> array

Array of strings of allowed identity document types. If the provided identity document isn’t one of the allowed types, the verification check will fail with a documentI<type>not_allowed error code.

=item C<require_id_number> boolean

Collect an ID number and perform an L<ID number check|https://stripe.com/docs/identity/verification-checks?type=id-number> with the document’s extracted name and date of birth.

=item C<require_live_capture> boolean

Disable image uploads, identity document images have to be captured using the device’s camera.

=item C<require_matching_selfie> boolean

Capture a face image and perform a L<selfie check|https://stripe.com/docs/identity/verification-checks?type=selfie> comparing a photo ID and a picture of your user’s face. L<Learn more|https://stripe.com/docs/identity/selfie>.


=back

=item C<id_number> hash

Configuration options to apply to the C<id_number> check.

=over 8

=item C<id_number>

This is an empty hash.


=back

=back

=head2 selfie hash

Result of the selfie check for this report.

It has the following properties:

=over 4

=item C<document> string

ID of the L<File|https://stripe.com/docs/api/files> holding the image of the identity document used in this check.

=item C<error> hash

Details on the verification error. Present when status is C<unverified>.

=over 8

=item C<code> string

A short machine-readable string giving the reason for the verification failure.

=item C<reason> string

A human-readable message giving the reason for the failure. These messages can be shown to your users.


=back

=item C<selfie> string

ID of the L<File|https://stripe.com/docs/api/files> holding the image of the selfie used in this check.

=item C<status> string

Status of this C<selfie> check.

=back

=head2 type string

Type of report.

=head2 verification_session string

ID of the VerificationSession that created this report.

=head1 API SAMPLE

[
   {
      "created" : "1662261086",
      "document" : {
         "address" : {
            "city" : "San Francisco",
            "country" : "US",
            "line1" : "1234 Main St.",
            "state" : "CA",
            "zip" : "94111"
         },
         "error" : null,
         "expiration_date" : {
            "day" : "1",
            "month" : "12",
            "year" : "2025"
         },
         "files" : [
            "file_MMt1QnXiGixEZxoe5FxvoMDx",
            "file_MMt1VGyZxCEW3uV9YvuOI7yx"
         ],
         "first_name" : "Jenny",
         "issued_date" : {
            "day" : "1",
            "month" : "12",
            "year" : "2020"
         },
         "issuing_country" : "US",
         "last_name" : "Rosen",
         "status" : "verified",
         "type" : "driving_license"
      },
      "id" : "vr_1Le9F42eZvKYlo2CHjM8lwqO",
      "livemode" : 0,
      "object" : "identity.verification_report",
      "options" : {
         "document" : {}
      },
      "type" : "document",
      "verification_session" : "vs_MMt1qTAB3jMvz6aXZCfHgulL"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/identity/verification_reports>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
