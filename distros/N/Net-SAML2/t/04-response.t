use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::Assertion;
use MIME::Base64;

my $xml = <<XML;
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="s2aa6f0dee017e82ced11a3c7c0be88ee42d3a9cb5" InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" Version="2.0" IssueInstant="2010-11-12T12:26:44Z" Destination="http://ct.local/saml/consumer-post"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">http://openam.nodnol.org:8080/opensso</saml:Issuer><samlp:Status xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">
<samlp:StatusCode xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" Value="urn:oasis:names:tc:SAML:2.0:status:Success">
</samlp:StatusCode>
</samlp:Status><saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="s2d1d09d5f190890fea3ecf12dc88cef287c77c3b5" IssueInstant="2010-11-12T12:26:44Z" Version="2.0">
<saml:Issuer>http://openam.nodnol.org:8080/opensso</saml:Issuer>
<saml:Subject>
<saml:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" NameQualifier="http://openam.nodnol.org:8080/opensso">W26qY2hXzKvOYdef/HS/xQxqBwD0</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
<saml:SubjectConfirmationData InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" NotOnOrAfter="2010-11-12T12:36:44Z" Recipient="http://ct.local/saml/consumer-post"/></saml:SubjectConfirmation>
</saml:Subject><saml:Conditions NotBefore="2010-11-12T12:16:44Z" NotOnOrAfter="2010-11-12T12:36:44Z">
<saml:AudienceRestriction>
<saml:Audience>http://ct.local</saml:Audience>
</saml:AudienceRestriction>
</saml:Conditions>
<saml:AuthnStatement AuthnInstant="2010-11-12T12:26:44Z" SessionIndex="s242c4fb93cf01015a82f4fac98769a0869f8bde01"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute Name="GUID"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">1234</saml:AttributeValue></saml:Attribute><saml:Attribute Name="EmailAddress"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">demo\@example.com</saml:AttributeValue></saml:Attribute></saml:AttributeStatement><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
            <dsig:SignedInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                <dsig:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                <dsig:Reference URI="#s2d1d09d5f190890fea3ecf12dc88cef287c77c3b5">
                        <dsig:Transforms>
                            <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                            <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </dsig:Transforms>
                        <dsig:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                        <dsig:DigestValue>qs6RhySf/pELLFucYFr2Uw0DZ+X0YvjWM3OdLQ8MCf0=</dsig:DigestValue>
                    </dsig:Reference>
            </dsig:SignedInfo>
            <dsig:SignatureValue>blPr777NBSfyuSIeWzBAwBXoKITaejwzaFc7+5VCL/9+QLYbOpDuYf58E75ckgd+WAtQJ7vHj5nY
dYhRyhFi48bcn75UUBiblNzFTE9Jnqw7tjUndMAbx+SfnEOKRgb/CJ2GSwombhSgtK9VIldm7s3w
rmY3BMB3AeBpT+SSHK8+dGGp79mFladp7zKf2saVe4IVcAW2rSYQUNOKjRbBRHmbKCLcvLuF/HrO
LTS7lfhXRheRkLwZtXESBMxz7CXturtYKwSKzuF4JAJ49r5Q0tqo/qxPjcQv9xIcUT4tpVUrKpq/
HnkvAPp2oFB4eAct+A3UMMIhugTa8O3oPolK2g==
</dsig:SignatureValue>
            <dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>
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
</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>
        </dsig:Signature></saml:Assertion><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
            <dsig:SignedInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                <dsig:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                <dsig:Reference URI="#s2aa6f0dee017e82ced11a3c7c0be88ee42d3a9cb5">
                        <dsig:Transforms>
                            <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                            <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </dsig:Transforms>
                        <dsig:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                        <dsig:DigestValue>gGzeJlwxICEHkWJyX0Lx+lRqRlFyuQAgUPH7LeM2uQU=</dsig:DigestValue>
                    </dsig:Reference>
            </dsig:SignedInfo>
            <dsig:SignatureValue>SPRZzaF9PQu6q2ltDbuwHfDU6Kn5I83/2VmL3/K+noqQTPzPAaO4RY/GFFl06Y5bAhmMp1IoeNTC
X+1LquxaI8vJWgCya+zyK6ValTgzOcSbS6+Jt0WktY4bbyS2h6BeO6MbvIIVn4pAvAK4xVz3sCku
ZxwViAfk4ljqltjRGJk6zgQ3tTBXN/ZKV7biZzXpwvuBNpnAYXxLpIF6FnfYRiCBmobNXufm4kxZ
EvN6b+vmEWjcMjIXnXTkBDm/zx3B9CruuY1qIBbdjtFbVtYoG/4tfaMgPyNs75tnw0CTZ5Q2r21x
1H4B/awRyBK8BSWYBqXplvvp5DP/CEGWSogY4g==
</dsig:SignatureValue>
            <dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>
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
</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>
        </dsig:Signature></samlp:Response>
XML

my $response = encode_base64($xml);

my $sp = net_saml2_sp();

my $post = $sp->post_binding;

my $response_xml;

lives_ok(
    sub {
        $response_xml = $post->handle_response($response);
    },
    '$sp->handle_response works'
);


is($response_xml, $xml, "We have the response XML as XML");

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $response_xml);
isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');

done_testing;
