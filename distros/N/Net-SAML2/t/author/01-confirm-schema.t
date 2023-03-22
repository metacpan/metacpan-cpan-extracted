use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

if (!$ENV{AUTHOR_TESTING}) {
    plan skip_all => 'Author test skipped';
}

use MIME::Base64 qw/decode_base64/;
use XML::LibXML;
use Net::SAML2;

my $sp = net_saml2_sp();

my $metadata = path('t/data/idp-samlid-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/data/cacert-samlid.pem'
);
isa_ok($idp, "Net::SAML2::IdP");

my $xsd_filename = 't/data/saml-schema-protocol-2.0.xsd';

sub validate_schema {
    my ($xml, $message) = @_;

    my $doc = XML::LibXML->new->parse_string($xml);
    my $xmlschema = XML::LibXML::Schema->new( location => $xsd_filename, no_network => 0 );

    my $result;
    eval { $result = $xmlschema->validate( $doc ); };

    unlike ( $@, qr/Schemas validity error/, "XSD Schema Validation Succeeded for $message");
}

my $post = $sp->sp_post_binding($idp, 'SAMLRequest');
isa_ok($post, 'Net::SAML2::Binding::POST');

my $authnreq = $sp->authn_request(
    $idp->entityid,
    $idp->format('persistent')
)->as_xml;

my $post_request = $post->sign_xml($authnreq);
validate_schema(decode_base64($post_request), "AuthnRequest");

my $logoutreq = $sp->logout_request(
    $idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'),
    'timlegge@cpan.org',
    $idp->format || undef,
    '94750270472009384017107023022',
)->as_xml;

$post_request = $post->sign_xml($logoutreq);
validate_schema(decode_base64($post_request), "LogoutRequest");

my $logout_resp = Net::SAML2::Protocol::LogoutResponse->new(
    issuer      => 'https://netsaml2-testapp.local',
    destination => 'destination',
    status      => 'status',
    response_to => 'NETSAML2_dkajhdahdkhdkdj',
  )->as_xml;

$post_request = $post->sign_xml($logout_resp);
validate_schema(decode_base64($post_request), "LogoutResponse");

my $art_request = $sp->artifact_request(
                                    $idp->art_url("urn:oasis:names:tc:SAML:2.0:bindings:SOAP"),
                                    'dshsodowejd9323ne292jd2odh202d',
                                )->as_xml;

my $ua = LWP::UserAgent->new;

require LWP::Protocol::https;
$ua->ssl_opts( (verify_hostname => 1));

my $soap = Net::SAML2::Binding::SOAP->new(
        ua          => $ua,
        url         => $idp->art_url("urn:oasis:names:tc:SAML:2.0:bindings:SOAP"),
        key         => 't/net-saml2-key.pem',
        cert        => 't/net-saml2-cert.pem',
        idp_cert    => $idp->cert('signing'),
);

my $soap_request = $soap->create_soap_envelope($art_request);

$soap_request =~ s!(<samlp:ArtifactResolve.*?</samlp:ArtifactResolve>)!!s;
validate_schema($1, "ArtifactResolve");

done_testing;
