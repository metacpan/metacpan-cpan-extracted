package Punk::SAML::Error;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Error - what a refusal throws

=head1 DESCRIPTION

Every refusal in this distribution throws one of these: a blessed
hashref with a C<code> and a C<message>.

    eval { Punk::SAML::Response->verify($bytes, %opts) };
    if (ref $@) {
        warn "saml refused: $@->{code}";
    }

=head2 code

The interface. The route logs it, the tests assert on it, this page lists
it, and an operator greps for it. Codes are added, never reworded.

=head2 message

For the log. B<It never reaches the browser>: a verifier that tells the
far side which check it failed is telling an attacker which one to work
on next. Every refusal produces the same page.

=head1 CODES

=over 4

=item C<xml_parse>

the document is not well-formed XML, carries a DOCTYPE, or has two elements with the same ID.

=item C<xml_shape>

the document parsed but is not the shape a Response must have: a wrong root, a wrong Version, no Assertion or more than one, no Subject, no NameID, no bearer SubjectConfirmation, or no AuthnStatement.

=item C<bad_base64>

the SAMLResponse field is over max_response, or is not strict standard base64.

=item C<bad_datetime>

a timestamp is not an xs:dateTime in UTC. Core section 1.3.3 requires UTC, and an offset is refused rather than converted.

=item C<no_signature>

nothing is signed that require_signed requires to be.

=item C<bad_signature>

a signature is present and does not verify, for any reason: a Reference naming another element, a refused transform, or no configured key verifying it.

=item C<bad_digest>

the reference digest does not match the element the signature covers, which is what an edited assertion looks like.

=item C<alg_refused>

a SignatureMethod or DigestMethod this plugin does not accept, including rsa-sha1 and, on the digest side, SHA-1 without allow_sha1.

=item C<unknown_issuer>

the Issuer is not the provider's entity id.

=item C<no_key>

no signing certificate is configured for the provider.

=item C<expired>

the assertion or its subject confirmation window has passed, allowing skew.

=item C<not_yet_valid>

the assertion is not valid yet, allowing skew. Usually a clock difference larger than skew.

=item C<bad_audience>

no AudienceRestriction names this application.

=item C<bad_destination>

the Destination or the SubjectConfirmationData Recipient is not this application's assertion consumer URL.

=item C<bad_in_response_to>

the Response answers a different login, or answers one this application has no record of starting.

=item C<replay>

the assertion has been presented before.

=item C<unsolicited>

there is no flow record and allow_idp_initiated is off.

=item C<encrypted_assertion>

the Response carries an EncryptedAssertion, which is refused rather than decrypted.

=item C<status>

the provider returned a StatusCode other than Success. The nested code and any StatusMessage are in the message.

=item C<config>

a provider was misconfigured or its metadata could not be used.

=back

=head1 SEE ALSO

L<Punk::Plugin::SAML>, whose C<WHAT IS CHECKED> section gives these in
the order they are checked.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
