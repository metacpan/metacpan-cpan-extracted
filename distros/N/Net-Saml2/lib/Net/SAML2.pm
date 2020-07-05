package Net::SAML2;
use strict;
use warnings;

require 5.008_001;

our $VERSION = '0.28';
$VERSION = eval {$VERSION};


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

Net::SAML2

=head1 VERSION

version 0.28

=head1 SYNOPSIS

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
                        xml => decode_base64($saml_response)
                );

                # ...
        }

=head1 DESCRIPTION

Support for the Web Browser SSO profile of SAML2.

This is a very early release, but one which will correctly perform the
SSO process.

=head1 NAME

Net::SAML2 - SAML bindings and protocol implementation

=head1 MAJOR CAVEATS

=over

=item SP-side protocol only

=item Requires XML metadata from the IdP

=back

=head1 AUTHOR

Chris Andrews <chrisandrews@venda.com>

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2010, 2011 Venda Ltd.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Andrews and Others; in detail:

  Copyright 2010-2012  Chris Andrews
            2016       Jeff Fearn
            2017       xmikew
            2019-2020  Timothy Legge


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
