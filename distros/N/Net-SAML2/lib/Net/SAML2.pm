use strict;
use warnings;
package Net::SAML2;
our $VERSION = '0.89';

require 5.012;

# ABSTRACT: SAML2 bindings and protocol implementation

# entities
use Net::SAML2::IdP;
use Net::SAML2::SP;
use Net::SAML2::RequestedAttribute;
use Net::SAML2::AttributeConsumingService;

# bindings
use Net::SAML2::Binding::Redirect;
use Net::SAML2::Binding::POST;
use Net::SAML2::Binding::SOAP;

# protocol
use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::Protocol::LogoutRequest;
use Net::SAML2::Protocol::LogoutResponse;;
use Net::SAML2::Protocol::Assertion;
use Net::SAML2::Protocol::Artifact;
use Net::SAML2::Protocol::ArtifactResolve;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2 - SAML2 bindings and protocol implementation

=head1 VERSION

version 0.89

=head1 SYNOPSIS

  See TUTORIAL.md for implementation documentation and
  t/12-full-client.t for a pseudo implementation following the tutorial

  # generate a redirect off to the IdP:

        my $idp = Net::SAML2::IdP->new($IDP);
        my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

        my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
                issuer        => 'http://localhost:3000/metadata.xml',
                destination   => $sso_url,
                nameid_format => $idp->format('persistent'),
        )->as_xml;

        my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
          id            => 'NETSAML2_Crypt::OpenSSL::Random::random_pseudo_bytes(16),
          issuer        => $self->{id},		# Service Provider (SP) Entity ID
          destination   => $sso_url,		# Identity Provider (IdP) SSO URL
          provider_name => $provider_name,	# Service Provider (SP) Human Readable Name
          issue_instant => DateTime->now,	# Defaults to Current Time
        );

        my $request_id = $authnreq->id;	# Store and Compare to InResponseTo

        # or

        my $request_id = 'NETSAML2_' . unpack 'H*', Crypt::OpenSSL::Random::random_pseudo_bytes(16);

        my $authnreq = Net::SAML2::Protocol::AuthnRequest->as_xml(
          id            => $request_id,		# Unique Request ID will be returned in response
          issuer        => $self->{id},		# Service Provider (SP) Entity ID
          destination   => $sso_url,		# Identity Provider (IdP) SSO URL
          provider_name => $provider_name,	# Service Provider (SP) Human Readable Name
          issue_instant => DateTime->now,	# Defaults to Current Time
        );

        my $redirect = Net::SAML2::Binding::Redirect->new(
                key => '/path/to/SPsign-nopw-key.pem',
                url => $sso_url,
                param => 'SAMLRequest' OR 'SAMLResponse',
                cert => '/path/to/IdP-cert.pem'
        );

        my $url = $redirect->sign($authnreq);

        my $ret = $redirect->verify($url);

  # handle the POST back from the IdP, via the browser:

        # Get the Assertion Consumer Service
        # $acs->{Location} can then be used to specify the
        # expected destination (you may choose other methods)

        my $acs = first { $_->{Binding} eq 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' }
            @{ $sp->assertion_consumer_service };

        # At least one of C<cacert> or C<cert_text> must be supplied at
        # construction, unless C<insecure_trust_embedded_cert> is set.
        # Without a C<cacert> or C<cert_text> the handle_response accepts
        # whatever signing certificate the response embeds in its KeyInfo
        # block, which is equivalent to no signature checking at all.
        # Has no effect on the binding's signing path (C<sign_xml>).

        my $post = Net::SAML2::Binding::POST->new(
            cacert                      => "IdP-cacert.pem", # Optional for sign_xml()
            insecure_trust_embedded_cert    => 0, Default - false require trust anchor
        );
        my $ret = $post->handle_response(
                $saml_response
        );

        if ($ret) {
                my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
                        xml         => decode_base64($saml_response),
                        key_file    => "SP-Private-Key.pem",    # Required for EncryptedAssertions
                        cacert      => "IdP-cacert.pem",        # Required unless insecure_trust_embedded_cert is true
                        issuer      => $idp->{entity_id},       # Maybe required in the future
                        destination => $acs->{Location},        # Maybe required in the future
                );

                # ...
        }

=head1 DESCRIPTION

Support for the Web Browser SSO profile of SAML2.

Version 0.54 and newer support EncryptedAssertions. No changes required to
existing SP applications if EncryptedAssertions are not in use.

Net::SAML2 correctly perform the SSO process against numerous SAML
Identity Providers (IdPs). It has been tested against:

=over

=item Auth0 (requires Net::SAML2 >=0.39)

=item Azure (Microsoft Office 365)

=item GSuite (Google)

=item Jump

=item Keycloak

=item MockSAML (https://mocksaml.com/)

=item Mircosoft ADFS

=item Okta

=item OneLogin

=item PingIdentity  (requires Net::SAML2 >=0.54)

=item SAMLTEST.ID (requires Net::SAML2 >=0.63)

=item Shibboleth (requires Net::SAML2 >=0.63)

=item SimpleSAMLphp

=item DigiD (requires Net::SAML2 >= 0.63)

=item eHerkenning (requires Net::SAML2 >= 0.73)

=item eIDAS (requires Net::SAML2 >= 0.73)

=back

=head1 MAJOR CAVEATS

=over

=item SP-side protocol only

=item Requires XML metadata from the IdP

=back

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
