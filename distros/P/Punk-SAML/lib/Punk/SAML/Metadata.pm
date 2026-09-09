package Punk::SAML::Metadata;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Metadata - SAML metadata, read and written

=head1 DESCRIPTION

Writes this service provider's own metadata, and signs it when a
deployment's provider requires that.

Reading an identity provider's metadata is L<Punk::SAML::IdP>.

=head1 METHODS

=head2 build (%opts)

The SP document. Takes C<entity_id>, C<acs_url>, and optionally C<cert>,
C<name_id_format>, C<authn_requests_signed> and
C<want_assertions_signed>.

C<acs_url> is passed in rather than derived, because the application
computed it once when it compiled and this must not become a second
answer to what its assertion consumer URL is.

=head2 sign ($xml, $id, $key_pem, $cert_pem)

An enveloped signature over the element carrying that C<ID>, spliced in
as its first child. Some providers refuse unsigned metadata by policy;
it is not otherwise needed, and metadata is a public document.

This is the one place this distribution creates an XML signature rather
than checking one, and it uses the same canonicalisation and the same
algorithms as the verifier. Be clear about what a test of it proves: a
signer that agrees with its own verifier would agree just as well if both
were wrong. What proves the canonicalisation is L<File::Raw::XML>'s
transcribed W3C vectors, and what proves this document is a provider
accepting it.

=head2 content_type

C<application/samlmetadata+xml>, which is the media type the
specification names. Punk's C<< $c->xml >> sends C<application/xml>; most
consumers accept either, and the ones that do not are exactly the strict
deployments this matters to.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
