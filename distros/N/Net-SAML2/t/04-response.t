use Test::More;
use Net::SAML2;
use MIME::Base64;
use Data::Dumper;

my $xml = <<XML;
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="s2aa6f0dee017e82ced11a3c7c0be88ee42d3a9cb5" InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" Version="2.0" IssueInstant="2010-11-12T12:26:44Z" Destination="http://ct.local/saml/consumer-post"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">http://openam.nodnol.org:8080/opensso</saml:Issuer><samlp:Status xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">
<samlp:StatusCode  xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
Value="urn:oasis:names:tc:SAML:2.0:status:Success">
</samlp:StatusCode>
</samlp:Status><saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="s2d1d09d5f190890fea3ecf12dc88cef287c77c3b5" IssueInstant="2010-11-12T12:26:44Z" Version="2.0">
<saml:Issuer>http://openam.nodnol.org:8080/opensso</saml:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
<ds:SignedInfo>
<ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
<ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
<ds:Reference URI="#s2d1d09d5f190890fea3ecf12dc88cef287c77c3b5">
<ds:Transforms>
<ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
<ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
</ds:Transforms>
<ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
<ds:DigestValue>BBMCOv+ILM/szUqBKyWBY3meyXA=</ds:DigestValue>
</ds:Reference>
</ds:SignedInfo>
<ds:SignatureValue>
sM2FSfk1L66V6s4OyaK0tGSgBMDl6rFPi14bR2FgR++64DiCgXzJeIhDO4CeACl8yGQLBiNHZBo2
hT635YGP0+8LSqWbrXJICpsEJVdfnpXJAP9dOc/u9yiH/3qQVtinz00ZrnV1DgqrQYp7TWVbXerd
VPt5U1IOHMBHYqgsYbc=
</ds:SignatureValue>
<ds:KeyInfo>
<ds:X509Data>
<ds:X509Certificate>
MIIDDDCCAfSgAwIBAgIBBDANBgkqhkiG9w0BAQUFADA3MQswCQYDVQQGEwJVUzEOMAwGA1UECgwF
bG9jYWwxCzAJBgNVBAsMAmN0MQswCQYDVQQDDAJDQTAeFw0xMDEwMDYxNDE5MDJaFw0xMTEwMDYx
NDE5MDJaMGMxCzAJBgNVBAYTAkdCMQ8wDQYDVQQIEwZMb25kb24xDzANBgNVBAcTBkxvbmRvbjEO
MAwGA1UEChMFVmVuZGExDDAKBgNVBAsTA1NTTzEUMBIGA1UEAxMLUlNBIE9wZW5TU08wgZ8wDQYJ
KoZIhvcNAQEBBQADgY0AMIGJAoGBALatk5hsXZA1BVxgFmWsAHna/ok3wMIYAtf2S4pTWlhgYEEt
z8btVPzOxLQ4eu6zAQHoPvOuZf0/LzQuhDgHVxX2x0BS/f5CfEC1Tx+gcSlINKz5pc1eylERMszX
HrgJEqc5qJL/hqizrPQSTa5c4P1tOApUGmr5ri3GWs+j/OQhAgMBAAGjezB5MAkGA1UdEwQCMAAw
LAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJhdGVkIENlcnRpZmljYXRlMB0GA1UdDgQWBBTJ
jwYYJePNfPQLlfplEcTJjF4NNzAfBgNVHSMEGDAWgBTWcCDL1HYlBpul6nAYYaX4JGy0FDANBgkq
hkiG9w0BAQUFAAOCAQEAK37Jlh5FxY4Zzph9Q2lkPwBQpHqSM7WeWjOMlQo2cP3oPpbPMohmZwQn
cNOdHgxERqJ4C4c+olRwFxxA7D/S90emxn9c/dyv3zQIJtNwguhcEX35MaqEFUGvbqnmJukEzdbJ
m4FU2FC0qGni7Jkvx/bCmS2xvdf71sR2HKSzqmUHys4PAHJhFCVdQXfROlO+964Oxab/HzFUwDCf
0wzJVksEB4DhP2sJtUIBJTpwofywMX5qLQuM6qPUJ/lRqpaxPOweKlkC5ndFnPtChc0+ZsJI3sBt
tz+07qyeZJJ8QNx9pRjKr9G8jtj5lXX+BOWizUt7QBTYNFQgWibMs3Ekmg==
</ds:X509Certificate>
</ds:X509Data>
</ds:KeyInfo>
</ds:Signature><saml:Subject>
<saml:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" NameQualifier="http://openam.nodnol.org:8080/opensso">W26qY2hXzKvOYdef/HS/xQxqBwD0</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
<saml:SubjectConfirmationData InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" NotOnOrAfter="2010-11-12T12:36:44Z" Recipient="http://ct.local/saml/consumer-post"/></saml:SubjectConfirmation>
</saml:Subject><saml:Conditions NotBefore="2010-11-12T12:16:44Z" NotOnOrAfter="2010-11-12T12:36:44Z">
<saml:AudienceRestriction>
<saml:Audience>http://ct.local</saml:Audience>
</saml:AudienceRestriction>
</saml:Conditions>
<saml:AuthnStatement AuthnInstant="2010-11-12T12:26:44Z" SessionIndex="s242c4fb93cf01015a82f4fac98769a0869f8bde01"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute Name="GUID"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">1234</saml:AttributeValue></saml:Attribute><saml:Attribute Name="EmailAddress"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">demo\@example.com</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion></samlp:Response>
XML

my $response = encode_base64($xml);

my $sp = Net::SAML2::SP->new(
        id               => 'http://localhost:3000',
        url              => 'http://localhost:3000',
        cert             => 't/sign-nopw-cert.pem',
        cacert           => 't/cacert.pem',
        org_name         => 'Test',
        org_display_name => 'Test',
        org_contact      => 'test@example.com',
);

my $post = $sp->post_binding;
my $subject = $post->handle_response($response);
ok($subject);
ok(qr/verified/, $subject);
#diag "subject: $subject\n";

my $assertion_xml = decode_base64($response);
my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
        xml => $xml,
);
ok($assertion);
#diag Dumper { assertion => $assertion };

done_testing;
