package Test::Net::SAML2::Util;
use warnings;
use strict;

# ABSTRACT: Utils for testsuite of Net::SAML2

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    get_xpath
    test_xml_attribute_ok
    test_xml_value_ok
    net_saml2_sp
    looks_like_a_cert
    net_saml2_binding_redirect_request
 );

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
);

use XML::LibXML::XPathContext;
use XML::LibXML;
use Sub::Override;
use Test::More;
use Test::Exception;
use Net::SAML2::SP;
use Net::SAML2::Util qw(generate_id);
use Crypt::OpenSSL::X509;
use URI::URL;

sub net_saml2_sp {
    return Net::SAML2::SP->new(
        id               => 'http://localhost:3000',
        url              => 'http://localhost:3000',
        cert             => 't/sign-nopw-cert.pem',
        key              => 't/sign-nopw-cert.pem',
        cacert           => 't/cacert.pem',
        org_name         => 'Test',
        org_display_name => 'Test',
        org_contact      => 'test@example.com',
        org_url          => 'http://www.example.com',
        slo_url_soap     => '/slo-soap',
        slo_url_redirect => '/sls-redirect-response',
        slo_url_post     => '/sls-post-response',
        acs_url_post     => '/consumer-post',
        acs_url_artifact => '/consumer-artifact',
        org_name         => 'Net::SAML2 Saml2Test',
        org_display_name => 'Saml2Test app for Net::SAML2',
        org_contact      => 'saml2test@example.com',
        error_url        => '/error',
        authnreq_signed  => '0',
        want_assertions_signed => '0',
        @_,
    );
}

#########################################################################
# net_saml2_binding_redirect_request
#
# Parameter:    $url
#
# Acts as the interface to an IdP that would normally be done by the user
# and browser to login.  Decodes the url and responds with a SAMLResponse
# with the options that are built from the IdP metadata, AuthnRequest and
# those that the IdP would normally set as in the function
#
# Response: base64 encoded signed xml
##########################################################################
sub net_saml2_binding_redirect_request {
    my ($url) = @_;

    use Path::Tiny;
    use MIME::Base64;
    use DateTime;

    my $metadata_xml = path('t/net-saml2-idp-metadata.xml')->slurp;
    my $cacert       = 't/net-saml2-cacert.pem';
    my $cert_file    = 't/net-saml2-cert.pem';
    my $sp_acs_url   = 'http://ct.local/saml/consumer-post';

    my $nameid  = 'timlegge@cpan.org';
    my $fname   = 'Timothy';
    my $lname   = 'Legge';
    my $title   = 'Developer';
    my $email   = 'timlegge@cpan.org';
    my $phone1  = '4408675309';
    my $phone2  = '4408675310';

    my $idp = Net::SAML2::IdP->new_from_xml(
        xml => $metadata_xml,       # xml as a string
        cacert => $cacert,          # Filename of the Identity Providers CACert
    );

    my $sp_signing_cert = path($cert_file)->slurp;

    my $redirect = Net::SAML2::Binding::Redirect->new(
        key => '',
        cert => $sp_signing_cert,
        param => 'SAMLRequest',
        # The ssl_url destination for redirect
        url => $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
    );

    my ($request, $relaystate) = $redirect->verify($url);

    use XML::LibXML;
    my $dom = XML::LibXML->load_xml( string => $request );

    my $parser = XML::LibXML::XPathContext->new($dom);
    $parser->registerNs('saml2p', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $parser->registerNs('saml2', 'urn:oasis:names:tc:SAML:2.0:assertion');

    my $sp_id           = $parser->findvalue('saml2p:AuthnRequest/@ID');
    my $sp_audience     = $parser->findvalue('saml2p:AuthnRequest/saml2:Issuer');

    my $issue_instant   = DateTime->now(time_zone => 'UTC')->strftime('%FT%TZ');
    my $on_or_after     = DateTime->from_epoch(epoch => time() + 1000);

    my $response_id     = generate_id();
    my $assertion_id    = generate_id();

    my $res_xml = <<"RESPONSEDOC";
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<saml2p:Response xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"
                 Destination="$sp_acs_url"
                 ID="$response_id"
                 InResponseTo="$sp_id"
                 IssueInstant="$issue_instant"
                 Version="2.0">
  <saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">$idp->{entityid}</saml2:Issuer>
  <saml2p:Status>
    <saml2p:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" /></saml2p:Status>
  <saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"
                   ID="$assertion_id"
                   IssueInstant="$issue_instant"
                   Version="2.0">
    <saml2:Issuer>$idp->{entityid}</saml2:Issuer>
    <saml2:Subject>
      <saml2:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">$nameid</saml2:NameID>
      <saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml2:SubjectConfirmationData InResponseTo="$sp_id"
                                       NotOnOrAfter="$on_or_after"
                                       Recipient="$sp_acs_url" /></saml2:SubjectConfirmation>
    </saml2:Subject>
    <saml2:Conditions NotBefore="$issue_instant"
                      NotOnOrAfter="$on_or_after">
      <saml2:AudienceRestriction>
        <saml2:Audience>$sp_audience</saml2:Audience>
      </saml2:AudienceRestriction>
    </saml2:Conditions>
    <saml2:AttributeStatement>
      <saml2:Attribute Name="Email">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$email</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="fname">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$fname</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="lname">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$lname</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="phone">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$phone1</saml2:AttributeValue>
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$phone2</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="title">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              xsi:type="xs:anyType">$title</saml2:AttributeValue>
      </saml2:Attribute>
    </saml2:AttributeStatement>
    <saml2:AuthnStatement AuthnInstant="$issue_instant"
                          SessionIndex="$assertion_id">
      <saml2:AuthnContext>
        <saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml2:AuthnContextClassRef>
      </saml2:AuthnContext>
    </saml2:AuthnStatement>
  </saml2:Assertion>
</saml2p:Response>
RESPONSEDOC

    my $signer = Net::SAML2::XML::Sig->new(
        {
            key => 't/net-saml2-key.pem',
            x509 => 1,
            cert => 't/net-saml2-cert.pem',
            no_xml_declaration => 1,
        });
    my $response = encode_base64($signer->sign($res_xml),"\n");

    return $response;
}

sub get_xpath {
    my ($xml, %ns) = @_;

    my $xp = XML::LibXML::XPathContext->new(
        XML::LibXML->load_xml(string => $xml)
    );

    $xp->registerNs($_, $ns{$_}) foreach keys %ns;

    return $xp;
}

sub test_xml_attribute_ok {
    my ($xpath, $search, $value) = @_;

    my @nodes = $xpath->findnodes($search);
    if (is(@nodes, 1, "$search returned one node")) {
        if (ref $value eq 'Regexp') {
            return like($nodes[0]->getValue, $value,
                ".. and value is what we expect");
        }
        return is($nodes[0]->getValue, $value, ".. and has value '$value'");
    }
    return 0;
}

sub test_xml_value_ok {
    my ($xpath, $search, $value) = @_;

    my @nodes = $xpath->findnodes($search);
    if (is(@nodes, 1, "$search returned one node")) {
        if (ref $value eq 'Regexp') {
            return like($nodes[0]->textContent, $value,
                ".. and value is what we expect");
        }
        return is($nodes[0]->textContent, $value, ".. and has value '$value'");
    }
    return 0;
}

sub looks_like_a_cert {
    my $cert = shift;
    lives_ok(
        sub {
            Crypt::OpenSSL::X509->new_from_string($cert);
        },
        "Looks like a certificate"
    );
}


1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Test::Net::SAML2::XML;

    my $xpath = get_xpath($xml);
    # go from here
