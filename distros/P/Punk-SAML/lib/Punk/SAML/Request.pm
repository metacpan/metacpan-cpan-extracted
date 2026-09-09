package Punk::SAML::Request;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Request - the AuthnRequest and its binding

=head1 DESCRIPTION

Builds an AuthnRequest, encodes it for the HTTP-Redirect binding, and
signs the redirect.

Usable with no application booted: the login route supplies the arguments
from the configuration, and nothing here reads it.

=head1 METHODS

=head2 new_id

A fresh request id: an underscore and 32 hex characters. The underscore
is not decoration. The C<ID> attribute is C<xs:ID>, whose lexical space
is an XML Name, and an XML Name may not begin with a digit; a provider
that validates the schema refuses a request whose ID does.

=head2 build (%args)

The C<AuthnRequest> document. Takes C<id>, C<instant>, C<destination>,
C<acs_url>, C<issuer>, and optionally C<name_id_format> and
C<force_authn>.

C<destination> is the provider's single sign-on URL as configured, copied
and never derived: some providers compare it against the URL they
received the request on and refuse a mismatch.

C<NameIDPolicy> is emitted only when C<name_id_format> is given. A policy
the provider cannot satisfy comes back as a C<Responder> status and a
failed login; letting the provider choose is what works everywhere.

=head2 redirect_url ($sso_url, $xml, $relay, $key_pem)

The HTTP-Redirect target: the document raw-deflated, base64'd and
URL-encoded, with C<RelayState> and, when a key is given, C<SigAlg> and
C<Signature>.

The deflate is RFC 1951 with no header, not zlib and not gzip. A header
is the commonest reason a provider answers "invalid request" with no
further detail.

C<$relay> is a flow id and never a URL. The return path lives in the flow
record on this side, where neither the provider nor an attacker can
rewrite it.

The signature is computed over the query string B<as sent>, in the order
Bindings section 3.4.4.1 fixes, with C<RelayState> omitted entirely when
there is none. The C<SigAlg> follows the key: RSA signs C<rsa-sha256>, EC
signs C<ecdsa-sha256>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
