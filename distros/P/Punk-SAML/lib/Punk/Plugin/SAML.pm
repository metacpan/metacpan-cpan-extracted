package Punk::Plugin::SAML;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::Plugin::SAML - sign in with SAML 2.0 identity providers

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::SAML;

    host 'https://app.example.com';
    session secret => secret('session_key');
    auth model => 'User';

    plugin 'SAML' => {
        secret => secret('saml.flow_key'),
    };

    saml_idp okta => {
        metadata => 'https://example.okta.com/app/abc123/sso/saml/metadata',
    };

    saml_login '/saml' => { on_login => sub {
        my ($c, $identity) = @_;
        my $user = $c->model('User')->find_or_create_by_email(
            $identity->{attributes}{email}[0]);
        $c->login($user);
        return;                              # the plugin redirects
    } };

=head1 DESCRIPTION

This plugin signs users into a Punk application through a SAML 2.0
identity provider: their Okta, their Entra ID, their ADFS. It implements
the Web Browser SSO profile as a B<service provider>, with HTTP-Redirect
outbound and HTTP-POST inbound, which is the combination every identity
provider supports.

=head1 DEVELOPMENT OVER PLAIN HTTP IS NOT SUPPORTED

The identity provider answers by C<POST>ing to this application from its
own origin. That is a cross-site C<POST>, and B<a cookie with
C<SameSite=Lax> is not sent on one>: Lax covers top-level navigations
with safe methods only. Punk's session cookie is Lax, as it should be, so
at the moment the assertion arrives the session is not there.

So this plugin keeps its flow record in a cookie of its own with
C<SameSite=None>, which is the only value a browser sends on that
request, and which browsers drop unless C<Secure> is also set. C<Secure>
needs C<https>. That is why the plugin refuses to boot when C<host> is
not C<https>, and it refuses loudly: over plain C<http> nothing fails at
startup, every login fails at the assertion consumer as C<unsolicited>,
and nothing in the log says why.

Two ways to work locally:

=over 4

=item * a local C<https> certificate, and C<host 'https://localhost:5000'>

=item * L<Punk::Test>, which does not go through a browser and has no
C<SameSite> to contend with

=back

=head1 OPTIONS

Given to C<plugin 'SAML' => { ... }>. An unknown option croaks, naming
what was available.

=over 4

=item C<secret>

B<Required>, and the plugin croaks at the C<plugin> line without it. It
signs the flow cookie. A secret minted per worker fails one login in four
the moment a redirect lands on a worker other than the one that started
it, and that failure looks like an intermittent fault at the identity
provider rather than a missing option. C<punk saml key> generates one.

A list rotates: the first signs, all of them verify, so a key can be
replaced with both live.

=item C<entity_id>

How the identity provider knows this application. Defaults to this
application's metadata URL, which is the convention every provider's
setup screen expects.

=item C<prefix>

Where this plugin's own paths live. Default C</saml>.

=item C<key>, C<cert>

The service provider's private key and certificate, in PEM. Needed only
for C<sign_requests> and C<sign_metadata>.

=item C<sign_requests>

Sign the C<AuthnRequest> on the redirect. Croaks without C<key>, because
an option that silently did nothing would have told the deployer the
opposite of the truth. Turns itself on when a provider's metadata says
C<WantAuthnRequestsSigned="true">, and croaks then if there is no C<key>,
because every login would otherwise fail.

=item C<sign_metadata>

Put an enveloped signature on the published metadata, for the providers
that refuse unsigned metadata by policy. Croaks without both C<key> and
C<cert>.

=item C<require_signed>

One of C<assertion>, C<response>, C<either> or C<both>. Default
C<either>: a verified signature on the C<Response> or on the
C<Assertion> satisfies it, because providers differ on which they sign by
default and a fresh integration should not fail on that. A signature on
the C<Response> covers the C<Assertion> inside it. An unrecognised word
is refused rather than defaulted, since a misspelling that quietly meant
C<either> would be a weaker check than the deployment asked for. Failure
code C<no_signature>.

=item C<skew>

Seconds of clock disagreement tolerated, on both edges. Default 120,
because identity providers' clocks are worse than anyone expects. An
C<expired> in the log against an assertion that looks fresh usually means
the two clocks differ by more than this.

=item C<flow_ttl>

Seconds a login may take, from the redirect to the assertion. Default
600. Also the flow cookie's C<Max-Age>.

=item C<max_response>

Bytes of C<SAMLResponse> accepted before decoding. Default 262144, which
is ten times the largest real C<Response> anyone has seen. The cap is on
the encoded field because that is the byte count an attacker controls at
the door. Failure code C<bad_base64>.

=item C<allow_sha1>

Permits a SHA-1 C<DigestMethod>. It does B<not> permit an C<rsa-sha1>
signature, which is refused whatever this is set to. Failure code
C<alg_refused>.

=item C<allow_idp_initiated>

See L</IDP-INITIATED SIGN-IN>. Off by default. Failure code
C<unsolicited>.

=item C<default_to>

Where a login lands when nothing said otherwise. Default C</>.

=item C<name_id_format>

Sent as C<NameIDPolicy>. Unset by default, which lets the provider
choose, and that is what works everywhere: a format the provider cannot
satisfy comes back as a C<Responder> status and a failed login.

=item C<force_authn>

Ask the provider to re-authenticate even if the user has a session there.

=item C<metadata>

Serve this application's metadata at C<< <prefix>/metadata >>. On by
default: an application that does not publish its metadata has to be
configured by hand at the other end, every time.

=item C<metadata_refresh>

Seconds between refetches of a provider's metadata on an unknown signer.
Default 3600. See L</KEY ROTATION>.

=item C<render>

A coderef or the name of a context method, replacing the failure page.

=back

C<host> is not an option of this plugin but it is required by it: the
plugin croaks at boot when the application has no C<host>, or when it is
not C<https>. The assertion consumer URL derives from it and the identity
provider compares that URL against what it was configured with character
for character, so it cannot be guessed from a request header.

=head1 PROVIDERS

    saml_idp okta  => { metadata => 'https://.../metadata' };
    saml_idp entra => { metadata => 'file:/etc/myapp/entra.xml' };
    saml_idp adfs  => {
        entity_id => 'http://adfs.example.com/adfs/services/trust',
        sso_url   => 'https://adfs.example.com/adfs/ls/',
        certs     => [ $pem1, $pem2 ],
    };

Repeatable; the name is what the login route uses. C<metadata> and the
explicit trio are exclusive, and giving both croaks rather than letting
one silently decide which key verifies an assertion.

Metadata is fetched or read once, at boot, before the server forks. B<A
fetch that fails at boot is a croak, not a warning>: an application whose
only login is SAML cannot sign anyone in without its provider, and
refusing to start says so at deploy time, in the deploy log, to the
person deploying. A warning would say it at the first login, to a user,
as a 403.

What is read: the entity id; the C<SingleSignOnService> with the
HTTP-Redirect binding; every C<KeyDescriptor> that is for signing; the
C<NameIDFormat>s, which are kept for C<punk saml idp> to print;
C<WantAuthnRequestsSigned>.

A C<KeyDescriptor> counts as a signing key when C<use="signing"> B<or
when there is no C<use> attribute at all> - the specification says a
missing C<use> means the key serves both purposes, and providers omit it
constantly. All of them are kept, in the order published, and every one
is tried: a provider mid-rotation publishes two.

A provider that offers only the HTTP-POST binding for single sign-on is
refused at boot. This plugin sends by redirect, and a request sent by
redirect to a POST-only endpoint is an error the provider phrases
unhelpfully, at a user, hours later.

Federation metadata - an C<EntitiesDescriptor> holding several entities -
needs C<entity_id> naming which one. Without it the refusal lists the ids
found, so it can be fixed in one step.

=head2 Certificate validity

Certificate validity dates are B<not> enforced by default. Providers
routinely sign with certificates that expired months ago, the trust here
is the certificate the deployment configured rather than a chain, and
refusing one helps nobody. C<enforce_cert_validity> turns the check on
for a deployment whose policy requires it. C<punk saml idp> prints the
fingerprints so an operator can see a rotation coming.

=head1 THE LOGIN

    saml_login '/saml' => {
        on_login => sub { my ($c, $identity) = @_; ... },   # required
        on_error => sub { my ($c, $error)    = @_; ... },   # optional
    };

Declared once. One application has one login mount, and every provider
lives under it.

C<on_login> receives the context and the verified identity. It returns a
response to answer for itself, or nothing, and the plugin redirects to
wherever the login started.

B<An C<on_login> that does not call C<< $c->login >> has verified an
assertion and signed nobody in.> That is legal - an application may want
the identity for something other than a session - but it is the common
mistake, and it looks like a login that works followed by a guard that
refuses.

=head2 The identity

    {
        idp             => 'okta',
        name_id         => 'jo@example.com',
        name_id_format  => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
        attributes      => { email => ['jo@example.com'],
                             groups => ['staff', 'eng'] },
        friendly        => { 'E-Mail Address' => ['jo@example.com'] },
        session_index   => '_a1b2...',
        authn_instant   => 1725600000,
        not_on_or_after => 1725600300,
        assertion_id    => '_c3d4...',
        raw             => $xml_bytes,
    }

B<Every attribute value is an arrayref, always, including when there is
one value.> SAML attributes are multi-valued and C<groups> is the one
everybody uses; an API that returned a scalar for one value and an
arrayref for two would be the bug in every C<on_login> body on the day a
user joins a second group. A provider that sends the same C<Name> twice
has its values merged rather than replaced.

C<friendly> is the same map keyed by C<FriendlyName>, for the providers
that set one, because the C<Name> some providers send is a URL nobody
wants to type.

B<Authorise on C<attributes>, never on C<friendly>.> C<Name> is the
identifier and is unique; C<FriendlyName> is a display label the provider
may put on more than one attribute, and when it does, their values are
merged under that one key. Two attributes meaning different things can
therefore arrive as one entry in C<friendly>. It is for showing to a
person, not for deciding what one may do.

C<raw> is the bytes as received, for an application that must keep an
audit record of what it accepted. C<session_index> is recorded so that a
later release can add logout without a schema change.

=head2 Composing with Punk::Auth

C<auth_guard> needs nothing new: it looks at the session, C<< $c->login >>
wrote it, and a SAML user is a user.

    saml_login '/saml' => { on_login => sub {
        my ($c, $identity) = @_;
        my $email = $identity->{attributes}{email}[0]
            or return $c->text('no email attribute from the provider', 403);
        $c->login(find_or_create_by_email($c, $email));
        return;
    } };

=head1 WHAT IS CHECKED

In order. Cheap before expensive, structural before cryptographic, and
B<the signature before anything the signature protects is read>. Each
check names the code it fails with.

=over 4

=item * The encoded C<SAMLResponse> is within C<max_response> - C<bad_base64>

=item * It is strict standard base64. Line wrapping is accepted, because
several providers wrap at 76 columns; the base64url alphabet is not -
C<bad_base64>

=item * It parses as XML. A C<DOCTYPE> is refused wherever it stands, so
external entities, XXE and entity expansion are not reachable from a
request at all - C<xml_parse>

=item * Two elements carrying the same C<ID> are refused at parse, before
anything is verified: "which element does this signature name" is the
whole of the wrapping attack - C<xml_parse>

=item * The root is C<samlp:Response> and its C<Version> is C<2.0> -
C<xml_shape>

=item * The C<StatusCode> is C<Success>. The nested code and any
C<StatusMessage> go to the log - C<status>

=item * There is no C<EncryptedAssertion> - C<encrypted_assertion>

=item * There is exactly one C<Assertion> - C<xml_shape>

=item * A signature is present as required by C<require_signed> -
C<no_signature>

=item * Every signature present verifies: the algorithm is accepted
(C<alg_refused>), the reference digest matches (C<bad_digest>), and a
configured key verifies it (C<bad_signature>, or C<no_key> when none is
configured)

=item * The C<Issuer> is the provider's entity id - C<unknown_issuer>

=item * The C<Destination>, when present, is this application's assertion
consumer URL - C<bad_destination>

=item * C<Conditions/@NotBefore> is not in the future beyond C<skew> -
C<not_yet_valid>

=item * C<Conditions/@NotOnOrAfter> has not passed, allowing C<skew> -
C<expired>

=item * An C<AudienceRestriction> names this application's entity id -
C<bad_audience>

=item * There is a C<NameID> and a bearer C<SubjectConfirmation> -
C<xml_shape>

=item * The C<SubjectConfirmationData/@Recipient> is this application's
assertion consumer URL, and its window has not closed -
C<bad_destination>, C<expired>

=item * The C<InResponseTo> matches the login this application started -
C<bad_in_response_to>

=item * A response to no login at all is refused unless
C<allow_idp_initiated> - C<unsolicited>

=item * There is an C<AuthnStatement>, which is what makes this an
authentication rather than an attribute query - C<xml_shape>

=item * The assertion has not been presented before - C<replay>

=item * Every timestamp is a well-formed C<xs:dateTime> in UTC. A
timezone offset is refused: Core section 1.3.3 requires UTC -
C<bad_datetime>

=back

Every one of these produces the same page for the browser: "sign-in
failed" and a link to try again. The code is written to the log with the
provider name. B<The reason never reaches the browser>, because a
verifier that tells the far side which check it failed is telling an
attacker which one to work on next.

=head2 The signature rule

The reason SAML libraries have had a decade of authentication bypasses is
that the signed thing and the read thing were allowed to differ. An
attacker takes a signed assertion for their own account, adds an unsigned
one for the administrator's, and arranges the document so that the
verifier finds one and the attribute reader finds the other. Every
published variant of the attack is that.

The rule here, applied without exception:

B<The element whose child the signature is, is the element the signature
covers, is the element the identity is read from.>

Concretely: a C<ds:Signature> counts only as a direct child, so one
placed inside C<Extensions>, inside C<Subject> or inside another
assertion's C<Advice> is not looked at and makes nothing signed. There
must be exactly one C<Reference>, and its C<URI> must be C<#> plus the
C<ID> of the element the signature is a child of - and that is checked by
identity, not by comparing id strings, so an element that merely looks
the same will not do. The transforms must be exactly
C<enveloped-signature> then exclusive canonicalisation: XPath, XSLT and
base64 transforms are refused, because those are the transforms that let
a signature cover something other than what it appears to. C<KeyInfo> in
the message is never trusted; every key tried is one the deployment
configured.

Once the signature is proven, the identity is read from that element and
no other. There is no second lookup and no search from the document root.

=head1 KEY ROTATION

Providers rotate signing keys by publishing the new certificate in
metadata ahead of the switch. Every certificate a provider publishes is
kept and every one is tried, so a rotation that is published in advance
works without any action here.

A rotation that is B<not> published in advance is handled by re-reading
the metadata. When a Response fails because no configured key verifies
its signature, and the provider was configured with C<metadata>, the
metadata is read again and the Response is verified once more against
whatever it now publishes. A provider given as an explicit
C<entity_id>/C<sso_url>/C<certs> trio is never refetched: those are the
values the deployment supplied, and they are not replaced from the
network.

The refetch is rate limited by C<metadata_refresh>, which defaults to an
hour. That is not politeness. A failed signature is also what a forged
Response produces, so without a limit anyone able to POST to the
assertion consumer URL could make this application fetch a URL on demand,
as often as they liked. The limit is held per worker process, so a
deployment running N workers permits at most N refetches per interval.

Set C<metadata_refresh> to C<0> to turn the refetch off entirely and
require a restart after an unannounced rotation.

A failure to reach the provider during a refetch is not an error page: it
is logged, and the sign-in is refused as it would have been anyway.

C<enforce_cert_validity> makes an expired certificate a refusal instead
of a warning; see L</Certificate validity> for why it is off.

=head1 IDP-INITIATED SIGN-IN

A C<Response> that answers no request this application made. Off by
default, and the default is the interesting part.

An attacker who can get a victim's browser to C<POST> a valid assertion
for the B<attacker's> account signs the victim into the attacker's
account. Everything the victim then does - a document uploaded, an
address typed, a card added - happens in an account the attacker controls
and can read at leisure. It is a quiet attack and it does not look like
one from the inside.

Turning it on is a decision that the identity provider is trusted to that
degree, and that the flow record, which is single use and is the defence
against a replayed assertion in an application-initiated login, is not
needed. With it on, a login lands at C<default_to>, or at the provider's
C<RelayState> after C<< $c->safe_path >> has flattened it.

=head1 WHAT IS NOT SUPPORTED

=over 4

=item Single logout

Not offered. C<< $c->logout >> is B<local logout>: it ends this
application's session and leaves the session at the identity provider
alone, which is what nearly every service provider actually does.

Front-channel single logout asks the provider to send a C<LogoutRequest>
through the user's browser to every service provider in the session and
wait for each answer; it fails if any one of them is slow, down or buggy,
and the user's browser is the message bus. Back-channel single logout
needs a SOAP endpoint. Most deployments have it configured and few have
it working.

C<session_index> and C<name_id> are recorded in the session so that a
later release can add service-provider-initiated logout without a schema
change.

=item Encrypted assertions

Refused, with code C<encrypted_assertion>, and the message names the
setting to turn off at the provider. XML encryption is a second
cryptographic surface with its own history of padding-oracle attacks, and
the transport is already TLS.

=item C<rsa-sha1> signatures

Refused, with code C<alg_refused>, whatever C<allow_sha1> is set to.
C<allow_sha1> reaches the C<DigestMethod> only, which is the less harmful
of the two. Every identity provider deployed today signs with SHA-256 by
default.

=item SHA-384 and SHA-512 digests

Recognised and refused, with code C<alg_refused>. Signature algorithms
RS/ES 256, 384 and 512 are all accepted; it is the C<DigestMethod> side
that is limited to SHA-256, which is what every provider in the field
uses.

=item The artifact binding, the SOAP binding, attribute queries

Not offered. They need a back-channel client, and nobody deploys them.

=item C<AttributeQuery>, just-in-time provisioning, SCIM, group sync

Not this plugin's. The attributes it delivers are what those are built
from.

=back

=head1 COMMANDS

=head2 punk saml key

A secret for the flow cookie, which is what the C<secret> croak names.

=head2 punk saml metadata

This application's metadata, for the operator setting up the provider
with no server running.

    $ punk saml metadata
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
        entityID="https://app.example.com/saml/metadata">
      <md:SPSSODescriptor AuthnRequestsSigned="false"
          WantAssertionsSigned="true"
          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:AssertionConsumerService index="0" isDefault="true"
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location="https://app.example.com/saml/acs"/>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>

=head2 punk saml idp <file-or-url>

What this plugin reads from a provider's metadata. What to run when a
provider's metadata was refused, and what to paste into a ticket to their
administrator.

    $ punk saml idp /tmp/okta-metadata.xml
    entity_id  https://idp.example.com/entity
    sso_url    https://idp.example.com/sso
    signed     WantAuthnRequestsSigned=false
    cert 0     sha256:8a3093e2c8b880683ce231d950ea23915ae5031dd667580c69d8be82de7e6120
    nameid     urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress

Exit status 0 when the metadata was read, 1 when it was refused, and the
refusal prints as C<refused: code: message>.

=head2 punk saml verify <file>

The phase-6 checks over a saved C<SAMLResponse>, the base64 as it came or
the XML, printing the first refusal with its code. C<--at> moves the
clock, so an assertion saved yesterday can be checked today.

B<This is the tool for the support ticket that says "SSO stopped
working".> The operator saves the C<POST> from the browser's network tab,
runs this, and the answer is C<audience> or C<expired> or
C<unknown_issuer>. The ticket is then answerable without a reproduction.

=head1 SETTING UP A PROVIDER

Two values go from this application into the provider's console, and one
comes back.

=over 4

=item * B<The assertion consumer URL>, which is C<host> plus the login
mount plus C</acs>. Providers call it the ACS URL, the Reply URL, or the
Single Sign-On URL. Run C<punk saml metadata> and read the
C<AssertionConsumerService> C<Location>; that exact string is what the
provider must be given, because it compares it character for character.

=item * B<The entity id>, which defaults to this application's metadata
URL. Providers call it the Entity ID, the Identifier, or the Audience
URI. It is the C<entityID> attribute in the same document.

=item * B<The provider's metadata URL> comes back, and goes into
C<saml_idp>. Every provider can produce one; some of them put it behind a
login, in which case download it once and use C<file:>, or use the
explicit C<entity_id>/C<sso_url>/C<certs> form.

=back

Then C<punk saml idp <their-metadata>> before starting the application,
which reads the metadata the same way the plugin will and prints what it
found. A provider that this plugin cannot use fails there, at a terminal,
rather than at a user's first login.

=head2 Per-provider notes

B<These subsections are unverified.> They describe what each provider
calls the two values above, and nothing has been confirmed against a real
tenant of any of them. Console layouts and default attribute names change,
and a walkthrough that reads as observed and is not is worse than an
honest gap. Treat them as a starting vocabulary, not as instructions.

=over 4

=item Okta

The application is created as a SAML 2.0 app. Okta's "Single sign on URL"
is the assertion consumer URL and its "Audience URI (SP Entity ID)" is the
entity id. Attribute statements are configured explicitly, so the
attribute carrying the email address is whatever the administrator named
it - check with C<punk saml verify> against a real assertion rather than
assuming.

=item Entra ID

Formerly Azure AD. The "Reply URL (Assertion Consumer Service URL)" is the
assertion consumer URL and the "Identifier (Entity ID)" is the entity id.
Entra names attributes with schema URLs rather than short names, which is
what C<friendly> exists for.

=item Keycloak

A client in a realm. The "Valid redirect URIs" and "Master SAML Processing
URL" are involved; which one carries the assertion consumer URL depends on
the version. Keycloak publishes descriptor metadata per realm.

=item ADFS

A relying party trust. The assertion consumer URL is an endpoint of type
"SAML Assertion Consumer" with the POST binding; the entity id is the
relying party identifier. Claim rules decide which attributes are sent,
and by default there may be none.

=back

=head1 METHODS

Called by Punk's C<plugin> keyword rather than by an application.

=head2 new

=head2 register ($app, \%opts)

Validates the options, records them on the application, and installs the
keywords and helpers. The keywords are also installed by
C<use Punk::Plugin::SAML>, which is what makes them available to the
parser: C<saml_idp> and C<saml_login> are bareword calls, and the
C<plugin> line runs too late to help a line that has already been
compiled.

=head1 SEE ALSO

L<Punk>, L<Punk::Auth>, L<Punk::OAuth2>, L<Punk::SAML::Response>,
L<Punk::SAML::Error>, L<File::Raw::XML>, L<Crypt::JWS>.

Specifications: SAML 2.0 Core, Bindings (section 3.4.4.1 for the redirect
signature), Profiles (section 4.1 for Web Browser SSO), Metadata, and
Exclusive XML Canonicalization 1.0.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
