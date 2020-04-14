# perl-Net-SAML2

Perl Net::SAML2 module - version 0.20.03 and above

# NAME
 
Net::SAML2
 
# VERSION
 
version 0.20.03
 
# SYNOPSIS

## generate a redirect off to the IdP:
 
        my $idp = Net::SAML2::IdP->new($IDP);
        my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
 
        my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
                issuer        => 'http://localhost:3000/metadata.xml',
                destination   => $sso_url,
                nameid_format => $idp->format('persistent'),
        )->as_xml;
 
        my $redirect = Net::SAML2::Binding::Redirect->new(
                key => '/path/to/SPsign-nopw-key.pem',
                url => $sso_url,
                param => 'SAMLRequest' OR 'SAMLResponse',
                cert => '/path/to/IdP-cert.pem'
        );
 
        my $url = $redirect->sign($authnreq);
 
        my $ret = $redirect->verify($url);
 
## handle the POST back from the IdP, via the browser:
 
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
 
# DESCRIPTION
 
Support for the Web Browser SSO profile of SAML2.
 
This is a release has gone through quite a few updates since the 0.17
release.  It has been tested with the GSuite IdP and the 19.05 unreleased
version is in daily use against a Microsoft Azure (Office 365) IdP.
 
# NAME
 
Net::SAML2 - SAML bindings and protocol implementation

# MAJOR CAVEATS
 
   1. SP-side protocol only
   1. Requires XML metadata from the IdP
 
# LICENCE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
# AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

# CONTRIBUTERS

The following people have contributed code and fixed issues since
the last official version 0.17 by Chris Andrews

      Alessandro Ranellucci <aar@cpan.org>
      dmborque@gmail.com
      Jeff Fearn <jfearn@redhat.com>
      Mike Wisener <mwisener@secureworks.com>
      Mike Wisener <xmikew@cpan.org>
      Peter Marschall <peter@adpm.de>
      Timothy Legge <timlegge@gmail.com>
      xmikew <github@32ths.com>

# COPYRIGHT AND LICENSE

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2010, 2011 Venda Ltd.

This software is copyright Chris Andrews and Others as detailed in the GIT repo

  Copyright 2010-2012  Chris Andrews

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself. 
