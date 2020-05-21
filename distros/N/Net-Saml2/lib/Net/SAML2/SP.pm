package Net::SAML2::SP;
use Moose;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;


use Crypt::OpenSSL::X509;
use XML::Generator;


has 'url'    => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'id'     => (isa => Str, is => 'ro', required => 1);
has 'cert'   => (isa => Str, is => 'ro', required => 1);
has 'key'    => (isa => Str, is => 'ro', required => 1);
has 'cacert' => (isa => 'Maybe[Str]', is => 'ro', required => 1);

has 'org_name'         => (isa => Str, is => 'ro', required => 1);
has 'org_display_name' => (isa => Str, is => 'ro', required => 1);
has 'org_contact'      => (isa => Str, is => 'ro', required => 1);

has '_cert_text' => (isa => Str, is => 'rw', required => 0);


sub BUILD {
    my ($self) = @_;

    my $cert = Crypt::OpenSSL::X509->new_from_file($self->cert);
    my $text = $cert->as_string;
    $text =~ s/-----[^-]*-----//gm;
    $self->_cert_text($text);

    return $self;
}


sub authn_request {
    my ($self, $destination, $nameid_format) = @_;

    my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
        issueinstant  => DateTime->now,
        issuer        => $self->id,
        destination   => $destination,
        nameid_format => $nameid_format,
    );

    return $authnreq;
}


sub logout_request {
    my ($self, $destination, $nameid, $nameid_format, $session) = @_;

    my $logout_req = Net::SAML2::Protocol::LogoutRequest->new(
        issuer        => $self->id,
        destination   => $destination,
        nameid        => $nameid,
        nameid_format => $nameid_format,
        session       => $session,
    );

    return $logout_req;
}


sub logout_response {
    my ($self, $destination, $status, $response_to) = @_;

    my $status_uri = Net::SAML2::Protocol::LogoutResponse->status_uri($status);
    my $logout_req = Net::SAML2::Protocol::LogoutResponse->new(
        issuer      => $self->id,
        destination => $destination,
        status      => $status_uri,
        response_to => $response_to,
    );

    return $logout_req;
}


sub artifact_request {
    my ($self, $destination, $artifact) = @_;

    my $artifact_request = Net::SAML2::Protocol::ArtifactResolve->new(
        issuer       => $self->id,
        destination  => $destination,
        artifact     => $artifact,
        issueinstant => DateTime->now,
    );

    return $artifact_request;
}


sub sso_redirect_binding {
    my ($self, $idp, $param) = @_;

    my $redirect = Net::SAML2::Binding::Redirect->new(
        url   => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        cert  => $idp->cert('signing'),
        key   => $self->key,
        param => $param,
    );

    return $redirect;
}


sub slo_redirect_binding {
    my ($self, $idp, $param) = @_;

    my $redirect = Net::SAML2::Binding::Redirect->new(
        url   => $idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        cert  => $idp->cert('signing'),
        key   => $self->key,
        param => $param,
    );

    return $redirect;
}


sub soap_binding {
    my ($self, $ua, $idp_url, $idp_cert) = @_;

    my $soap = Net::SAML2::Binding::SOAP->new(
        ua       => $ua,
        key      => $self->key,
        cert     => $self->cert,
        url      => $idp_url,
        idp_cert => $idp_cert,
        cacert   => $self->cacert,
    );

    return $soap;
}


sub post_binding {
    my ($self) = @_;

    my $post = Net::SAML2::Binding::POST->new(
        cacert => $self->cacert,
    );

    return $post;
}


sub metadata {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty', conformance => 'loose');
    my $md = ['md' => 'urn:oasis:names:tc:SAML:2.0:metadata'];
    my $ds = ['ds' => 'http://www.w3.org/2000/09/xmldsig#'];

    $x->EntityDescriptor(
        $md,
        {
            entityID => $self->id },
        $x->SPSSODescriptor(
            $md,
            { AuthnRequestsSigned => '1',
              WantAssertionsSigned => '1',
              errorURL => $self->url . '/saml/error',
              protocolSupportEnumeration => 'urn:oasis:names:tc:SAML:2.0:protocol' },
            $x->KeyDescriptor(
                $md,
                {
                    use => 'signing' },
                $x->KeyInfo(
                    $ds,
                    $x->X509Data(
                        $ds,
                        $x->X509Certificate(
                            $ds,
                            $self->_cert_text,
                        )
                    )
                )
            ),
            $x->SingleLogoutService(
                $md,
                { Binding => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
                  Location  => $self->url . '/saml/slo-soap' },
            ),
            $x->SingleLogoutService(
                $md,
                { Binding => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
                  Location  => $self->url . '/saml/sls-redirect-response' },
            ),
            $x->AssertionConsumerService(
                $md,
                { Binding => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
                  Location => $self->url . '/saml/consumer-post',
                  index => '1',
                  isDefault => 'true' },
            ),
            $x->AssertionConsumerService(
                $md,
                { Binding => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact',
                  Location => $self->url . '/saml/consumer-artifact',
                  index => '2',
                  isDefault => 'false' },
            ),
        ),
        $x->Organization(
            $md,
            $x->OrganizationName(
                $md,
                {
                    'xml:lang' => 'en' },
                $self->org_name,
            ),
            $x->OrganizationDisplayName(
                $md,
                {
                    'xml:lang' => 'en' },
                $self->org_display_name,
            ),
            $x->OrganizationURL(
                $md,
                {
                    'xml:lang' => 'en' },
                $self->url
            )
        ),
        $x->ContactPerson(
            $md,
            {
                contactType => 'other' },
            $x->Company(
                $md,
                $self->org_display_name,
            ),
            $x->EmailAddress(
                $md,
                $self->org_contact,
            ),
        )
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::SP

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  my $sp = Net::SAML2::SP->new(
    id   => 'http://localhost:3000',
    url  => 'http://localhost:3000',
    cert => 'sign-nopw-cert.pem',
    key => 'sign-nopw-key.pem',
  );

=head1 NAME

Net::SAML2::SP - SAML Service Provider object

=head1 METHODS

=head2 new( ... )

Constructor. Create an SP object.

Arguments:

=over

=item B<url>

base for all SP service URLs

=item B<id>

SP's identity URI.

=item B<cert>

path to the signing certificate

=item B<key>

path to the private key for the signing certificate

=item B<cacert>

path to the CA certificate for verification

=item B<org_name>

SP organisation name

=item B<org_display_name>

SP organisation display name

=item B<org_contact>

SP contact email address

=back

=head2 BUILD ( hashref of the parameters passed to the constructor )

Called after the object is created to load the cert from a file

=head2 authn_request( $destination, $nameid_format )

Returns an AuthnRequest object created by this SP, intended for the
given destination, which should be the identity URI of the IdP.

=head2 logout_request( $destination, $nameid, $nameid_format, $session )

Returns a LogoutRequest object created by this SP, intended for the
given destination, which should be the identity URI of the IdP.

Also requires the nameid (+format) and session to be logged out.

=head2 logout_response( $destination, $status, $response_to )

Returns a LogoutResponse object created by this SP, intended for the
given destination, which should be the identity URI of the IdP.

Also requires the status and the ID of the corresponding
LogoutRequest.

=head2 artifact_request( $destination, $artifact )

Returns an ArtifactResolve request object created by this SP, intended
for the given destination, which should be the identity URI of the
IdP.

=head2 sso_redirect_binding( $idp, $param )

Returns a Redirect binding object for this SP, configured against the
given IDP for Single Sign On. $param specifies the name of the query
parameter involved - typically C<SAMLRequest>.

=head2 slo_redirect_binding( $idp, $param )

Returns a Redirect binding object for this SP, configured against the
given IDP for Single Log Out. $param specifies the name of the query
parameter involved - typically C<SAMLRequest> or C<SAMLResponse>.

=head2 soap_binding( $ua, $idp_url, $idp_cert )

Returns a SOAP binding object for this SP, with a destination of the
given URL and signing certificate.

XXX UA

=head2 post_binding( )

Returns a POST binding object for this SP.

=head2 metadata( )

Returns the metadata XML document for this SP.

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Andrews and Others; in detail:

  Copyright 2010-2011  Chris Andrews
            2012       Peter Marschall
            2017       Alessandro Ranellucci
            2019-2020  Timothy Legge


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
