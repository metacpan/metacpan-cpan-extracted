##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Identity/VerificationSession.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Identity::VerificationSession;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub last_error { return( shift->_set_get_class( 'last_error',
{ code => { type => "scalar" }, reason => { type => "scalar" } }, @_ ) ); }

sub last_verification_report { return( shift->_set_get_scalar_or_object( 'last_verification_report', 'Net::API::Stripe::Identity::VerificationReport', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

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

sub redaction { return( shift->_set_get_object( 'redaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

sub verified_outputs { return( shift->_set_get_object( 'verified_outputs', 'Net::API::Stripe::Connect::Person', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Identity::VerificationSession - The VerificationSession object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A VerificationSession guides you through the process of collecting and verifying the identities of your users. It contains details about the type of verification, such as what L<verification check|https://stripe.com/docs/identity/verification-checks> to perform. Only create one VerificationSession for each verification in your system.

A VerificationSession transitions through L<multiple statuses|https://stripe.com/docs/identity/how-sessions-work> throughout its lifetime as it progresses through the verification flow. The VerificationSession contains the user's verified data after verification checks are complete.

Related guide: L<The Verification Sessions API|https://stripe.com/docs/identity/verification-sessions>

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 client_secret string

The short-lived client secret used by Stripe.js to L<show a verification modal|https://stripe.com/docs/js/identity/modal> inside your app. This client secret expires after 24 hours and can only be used once. Don’t store it, log it, embed it in a URL, or expose it to anyone other than the user. Make sure that you have TLS enabled on any page that includes the client secret. Refer to our docs on L<passing the client secret to the frontend|https://stripe.com/docs/identity/verification-sessions#client-secret> to learn more.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 last_error hash

If present, this property tells you the last error encountered when processing the verification.

It has the following properties:

=over 4

=item C<code> string

A short machine-readable string giving the reason for the verification or user-session failure.

=item C<reason> string

A message that explains the reason for verification or user-session failure.

=back

=head2 last_verification_report expandable

ID of the most recent VerificationReport. L<Learn more about accessing detailed verification results.|https://stripe.com/docs/identity/verification-sessions#results>

When expanded this is an L<Net::API::Stripe::Identity::VerificationReport> object.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 options hash

A set of options for the session’s verification checks.

It has the following properties:

=over 4

=item C<document> hash

Options that apply to the L<document check|https://stripe.com/docs/identity/verification-checks?type=document>.

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

Options that apply to the L<id number check|https://stripe.com/docs/identity/verification-checks?type=id_number>.

=over 8

=item C<id_number>

This is an empty hash.


=back

=back

=head2 redaction object

Redaction status of this VerificationSession. If the VerificationSession is not redacted, this field will be null.

This is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 status string

Status of this VerificationSession. L<Learn more about the lifecycle of sessions|https://stripe.com/docs/identity/how-sessions-work>.

=head2 type string

The type of L<verification check|https://stripe.com/docs/identity/verification-checks> to be performed.

=head2 url string

The short-lived URL that you use to redirect a user to Stripe to submit their identity information. This URL expires after 48 hours and can only be used once. Don’t store it, log it, send it in emails or expose it to anyone other than the user. Refer to our docs on L<verifying identity documents|https://stripe.com/docs/identity/verify-identity-documents?platform=web&type=redirect> to learn how to redirect users to Stripe.

=head2 verified_outputs object

The user’s verified data.

This is a L<Net::API::Stripe::Connect::Person> object.

=head1 API SAMPLE

[
   {
      "client_secret" : null,
      "created" : "1662261086",
      "id" : "vs_1Le9F42eZvKYlo2Chf4NfVUc",
      "last_error" : null,
      "last_verification_report" : "vr_MMt18CcerTGCqLkvTzwaSqfw",
      "livemode" : 0,
      "metadata" : {},
      "object" : "identity.verification_session",
      "options" : {
         "document" : {
            "require_matching_selfie" : 1
         }
      },
      "redaction" : null,
      "status" : "verified",
      "type" : "document",
      "url" : null
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/identity/verification_sessions>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
