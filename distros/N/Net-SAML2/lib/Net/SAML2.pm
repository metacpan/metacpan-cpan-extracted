use strict;
use warnings;
package Net::SAML2;
our $VERSION = "0.59";

require 5.008_001;

# ABSTRACT: SAML2 bindings and protocol implementation


# entities
use Net::SAML2::IdP;
use Net::SAML2::SP;

# bindings
use Net::SAML2::Binding::Redirect;
use Net::SAML2::Binding::POST;
use Net::SAML2::Binding::SOAP;

# protocol
use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::Protocol::LogoutRequest;
use Net::SAML2::Protocol::LogoutResponse;;
use Net::SAML2::Protocol::Assertion;
use Net::SAML2::Protocol::ArtifactResolve;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2 - SAML2 bindings and protocol implementation

=head1 VERSION

version 0.59

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

        my $post = Net::SAML2::Binding::POST->new;
        my $ret = $post->handle_response(
                $saml_response
        );

        if ($ret) {
                my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
                        xml         => decode_base64($saml_response),
                        key_file    => "SP-Private-Key.pem",    # Required for EncryptedAssertions
                        cacert      => "IdP-cacert.pem",        # Required for EncryptedAssertions
                );

                # ...
        }

=head1 DESCRIPTION

Support for the Web Browser SSO profile of SAML2.

Net::SAML2 correctly perform the SSO process against numerous SAML
Identity Providers (IdPs).  It has been tested against:

=over

=item GSuite (Google)

=item Azure (Microsoft Office 365)

=item OneLogin

=item Jump

=item Mircosoft ADFS

=item Keycloak

=item Auth0 (requires Net::SAML2 >=0.39)

=item PingIdentity

Version 0.54 and newer support EncryptedAssertions.  No changes required to existing
SP applications if EncryptedAssertions are not in use.

=back

=head1 NAME

Net::SAML2 - SAML bindings and protocol implementation

=head1 MAJOR CAVEATS

=over

=item SP-side protocol only

=item Requires XML metadata from the IdP

=back

=head1 CONTRIBUTORS

=over

=item Chris Andrews <chris@nodnol.org>

=item Oskari Okko Ojala <okko@frantic.com>

=item Peter Marschall <peter@adpm.de>

=item Mike Wisener <xmikew@cpan.org>

=item Jeff Fearn <jfearn@redhat.com>

=item Alessandro Ranellucci <aar@cpan.org>

=item Mike Wisener <mwisener@secureworks.com>, xmikew <github@32ths.com>

=item xmikew <github@32ths.com>

=item Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2010, 2011 Venda Ltd.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Chris Andrews and Others, see the git log.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
