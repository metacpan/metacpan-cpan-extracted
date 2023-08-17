use strict;
use warnings;
use Net::SAML2;
use MIME::Base64 qw/decode_base64/;
use XML::LibXML;

use Test::Lib;
use Test::Net::SAML2;
my $sp = net_saml2_sp();

my $metadata = path('t/idp-metadata.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml    => $metadata,
    cacert => 't/cacert.pem'
);

my $authn = $sp->authn_request(
        $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'),
        $idp->format || '', # default format.
        )->as_xml();

my $post = $sp->sp_post_binding($idp, 'SAMLRequest');

my $signed = decode_base64($post->sign_xml($authn));

my $dom = XML::LibXML->load_xml( string => $signed );

my $parser = XML::LibXML::XPathContext->new($dom);
$parser->registerNs('saml2p', 'urn:oasis:names:tc:SAML:2.0:protocol');
$parser->registerNs('saml2', 'urn:oasis:names:tc:SAML:2.0:assertion');
$parser->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
ok($parser->exists('//dsig:Signature'), "The XML is now signed");

done_testing;
