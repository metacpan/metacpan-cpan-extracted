package Punk::SAML::Signature;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Signature - XML-DSig, verified and made

=head1 DESCRIPTION

Verifies an XML signature, and makes one over the documents this
distribution writes.

The rule, stated here because it is the rule the whole distribution
turns on: a signature is checked over the canonical form of the element
it covers, and the element it covers is the one its Reference names.
Never the document the element was found in, never the first element of
the right name, and never an element selected after the signature was
checked. Selecting one element and verifying another is the whole of the
signature wrapping attack.

=head1 THE RULE

B<The element whose child the signature is, is the element the signature
covers, is the element the identity is read from.>

This is repeated here, and not only in L<Punk::Plugin::SAML>, because
somebody will read this module on its own.

The reason SAML libraries have had a decade of authentication bypasses is
that those three were allowed to differ. An attacker takes a signed
assertion for their own account, adds an unsigned one for the
administrator's, and arranges the document so the verifier finds one and
the reader finds the other.

So: a signature counts only as a direct child of what it signs. There
must be exactly one C<Reference>, and its C<URI> must name that same
element - checked by identity rather than by comparing id strings, so an
element that merely looks the same will not do. The transforms must be
exactly C<enveloped-signature> then exclusive canonicalisation; XPath,
XSLT and base64 transforms are refused, because those are the transforms
that let a signature cover something other than what it appears to.
C<KeyInfo> in the message is never trusted.

=head1 SIGNING

This distribution creates a signature in one place only: the published
service provider metadata, for the providers that refuse unsigned
metadata by policy.

Be clear about what a test of that proves. The signer canonicalises the
same way the verifier does and signs through the same primitives, so a
test that signs here and verifies with this module proves the two agree -
and they would agree just as well if both were wrong. What proves the
canonicalisation is L<File::Raw::XML>'s transcribed W3C vectors, and what
proves the document is a provider accepting it.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
