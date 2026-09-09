package Punk::SAML::IdP;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::IdP - one identity provider

=head1 DESCRIPTION

An identity provider: its entity id, its single sign-on URL, and its
signing certificates with their fingerprints.

Usable with no application booted, because C<punk saml verify> has to
work against a saved document at two in the morning.

=head1 METHODS

=head2 read ($bytes, %opts)

Reads a provider out of metadata B<bytes>, not a URL. Fetching is a
separate thing, and keeping them apart is what lets every refusal below
be tested against a string rather than a network.

Returns a hashref: C<entity_id>, C<sso_url>, C<certs> (PEM, in the order
published), C<fingerprints> (SHA-256 hex over the same DER, so it is the
number a provider's console shows), C<name_id_formats> and
C<want_authn_requests_signed>.

C<entity_id> selects one entity from federation metadata. Without it, an
C<EntitiesDescriptor> holding several is refused with the ids listed.

=head2 What is refused

A provider publishing no HTTP-Redirect C<SingleSignOnService>, because
this plugin sends C<AuthnRequest>s by redirect and a redirect to a
POST-only endpoint is an error the provider phrases unhelpfully, at a
user, hours later.

A C<KeyDescriptor> is a signing key when C<use="signing"> B<or when there
is no C<use> attribute at all>: the specification says a missing C<use>
means both, and providers omit it constantly. C<use="encryption"> is not
one, and metadata with no signing certificate is refused.

A certificate that will not parse is refused here, at boot, rather than
at the first login.

Certificate validity dates are B<not> enforced by default. Providers
routinely sign with certificates that expired months ago, the trust here
is the configured key rather than a chain, and refusing one helps nobody.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
