package Net::SAML2::Binding::SOAP;
use Moose;
use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::XML::Util qw/ no_comments /;


use Net::SAML2::XML::Sig;
use XML::XPath;
use LWP::UserAgent;
use HTTP::Request::Common;


has 'ua' => (
    isa      => 'Object',
    is       => 'ro',
    required => 1,
    default  => sub { LWP::UserAgent->new }
);

has 'url'      => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'key'      => (isa => 'Str', is => 'ro', required => 1);
has 'cert'     => (isa => 'Str', is => 'ro', required => 1);
has 'idp_cert' => (isa => 'Str', is => 'ro', required => 1);
has 'cacert'   => (isa => 'Str', is => 'ro', required => 1);


sub request {
    my ($self, $message) = @_;
    my $request = $self->create_soap_envelope($message);

    my $soap_action = 'http://www.oasis-open.org/committees/security';

    my $req = POST $self->url;
    $req->header('SOAPAction' => $soap_action);
    $req->header('Content-Type' => 'text/xml');
    $req->header('Content-Length' => length $request);
    $req->content($request);

    my $ua = $self->ua;
    my $res = $ua->request($req);

    return $self->handle_response($res->content);
}


sub handle_response {
    my ($self, $response) = @_;

    # verify the response
    my $x = Net::SAML2::XML::Sig->new({ x509 => 1, cert_text => $self->idp_cert, exclusive => 1, });
    my $ret = $x->verify($response);
    die "bad SOAP response" unless $ret;

    # verify the signing certificate
    my $cert = $x->signer_cert;
    my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);
    $ret = $ca->verify($cert);
    die "bad signer cert" unless $ret;

    my $subject = sprintf("%s (verified)", $cert->subject);

    # parse the SOAP response and return the payload
    my $parser = XML::XPath->new( xml => no_comments($response) );
    $parser->set_namespace('soap-env', 'http://schemas.xmlsoap.org/soap/envelope/');
    $parser->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $saml = $parser->findnodes_as_string('/soap-env:Envelope/soap-env:Body/*');
    return ($subject, $saml);
}


sub handle_request {
    my ($self, $request) = @_;

    my $parser = XML::XPath->new( xml => no_comments($request) );
    $parser->set_namespace('soap-env', 'http://schemas.xmlsoap.org/soap/envelope/');
    $parser->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $saml = $parser->findnodes_as_string('/soap-env:Envelope/soap-env:Body/*');

    if (defined $saml) {
        my $x = Net::SAML2::XML::Sig->new({ x509 => 1, cert_text => $self->idp_cert, exclusive => 1, });
        my $ret = $x->verify($saml);
        die "bad signature" unless $ret;

        my $cert = $x->signer_cert;
        my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);
        $ret = $ca->verify($cert);
        die "bad certificate in request: ".$cert->subject unless $ret;

        my $subject = $cert->subject;
        return ($subject, $saml);
    }

    return;
}


sub create_soap_envelope {
    my ($self, $message) = @_;

    # sign the message
    my $sig = Net::SAML2::XML::Sig->new({
        x509 => 1,
        key  => $self->key,
        cert => $self->cert,
        exclusive => 1,
    });
    my $signed_message = $sig->sign($message);

    # OpenSSO ArtifactResolve hack
    #
    # OpenSSO's ArtifactResolve parser is completely hateful. It demands that
    # the order of child elements in an ArtifactResolve message be:
    #
    # 1: saml:Issuer
    # 2: dsig:Signature
    # 3: samlp:Artifact
    #
    # Really.
    #
    if ($signed_message =~ /ArtifactResolve/) {
        $signed_message =~ s!(<dsig:Signature.*?</dsig:Signature>)!!s;
        my $signature = $1;
        $signed_message =~ s/(<\/saml:Issuer>)/$1$signature/;
    }

    # test verify
    my $ret = $sig->verify($signed_message);
    die "failed to sign" unless $ret;

    my $soap = <<"SOAP";
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
<SOAP-ENV:Body>
$signed_message
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
SOAP
    return $soap;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::SOAP

=head1 VERSION

version 0.29

=head1 SYNOPSIS

  my $soap = Net::SAML2::Binding::SOAP->new(
    url => $idp_url,
    key => $key,
    cert => $cert,
    idp_cert => $idp_cert,
  );

  my $response = $soap->request($req);

=head1 NAME

Net::SAML2::Binding::Artifact - SOAP binding for SAML2

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the SOAP binding configured for
the given IdP service url.

Arguments:

=over

=item B<ua>

(optional) a LWP::UserAgent-compatible UA

=item B<url>

the service URL

=item B<key>

the key to sign with

=item B<cert>

the corresponding certificate

=item B<idp_cert>

the idp's signing certificate

=item B<cacert>

the CA for the SAML CoT

=back

=head2 request( $message )

Submit the message to the IdP's service.

Returns the Response, or dies if there was an error.

=head2 handle_response( $response )

Handle a response from a remote system on the SOAP binding.

Accepts a string containing the complete SOAP response.

=head2 handle_request( $request )

Handle a request from a remote system on the SOAP binding.

Accepts a string containing the complete SOAP request.

=head2 create_soap_envelope( $message )

Signs and SOAP-wraps the given message.

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Chris Andrews and Others; in detail:

  Copyright 2010-2011  Chris Andrews
            2012       Peter Marschall
            2019       Timothy Legge
            2020       Timothy Legge, Wesley Schwengle


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
