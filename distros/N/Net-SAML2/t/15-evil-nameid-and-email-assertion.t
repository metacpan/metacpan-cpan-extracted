use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Protocol::Assertion;

my $xml = <<'XML_FILE';
<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" ID="id-2806f1cc-9ec9-4b70-ae58-e252e58159f1" Version="2.0" IssueInstant="2021-11-26T01:36:44.454Z" InResponseTo="NETSAML2_1d8748c413abe58635d3c8b53b79633a" Destination="https://netsaml2-testapp.local/consumer-post">
  <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">https://idp.com/idp</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>
  <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" ID="id-f58787c2-38e8-4dd4-b2bb-74cad987c88e" Version="2.0" IssueInstant="2021-11-26T01:36:44.454Z">
    <saml:Issuer>https://idp.com/idp</saml:Issuer>
    <saml:Subject>
      <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">user@netsaml2.local<!---->.evil.com</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData NotOnOrAfter="2021-11-26T01:53:24.455Z" Recipient="https://netsaml2-testapp.local/consumer-post" InResponseTo="NETSAML2_1d8748c413abe58635d3c8b53b79633a"/></saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2021-11-26T01:35:44.455Z" NotOnOrAfter="2021-11-26T01:53:24.455Z">
      <saml:AudienceRestriction>
        <saml:Audience>https://netsaml2-testapp.local</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2021-11-26T01:36:44.455Z" SessionNotOnOrAfter="2021-11-26T01:53:24.455Z" SessionIndex="bb6a1d05-b292-4a3c-acfa-b2d9101dbb97">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef>
        <saml:AuthenticatingAuthority>https://idp.com/idp</saml:AuthenticatingAuthority>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="saml_subject" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">43712857-1df8-4f6e-b476-a8fdc4446dd1</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="NickName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">&#x30D1;&#x30B9;&#x30EF;&#x30FC;&#x30C9;&#x3092;&#x304A;&#x5FD8;&#x308C;&#x306E;&#x65B9;</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="FirstName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Tester</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="EmailAddress" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user@netsaml2.local<!---->.evil.com</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  <dsig:Signature>
            <dsig:SignedInfo xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                <dsig:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                <dsig:Reference URI="#id-f58787c2-38e8-4dd4-b2bb-74cad987c88e">
                        <dsig:Transforms>
                            <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                            <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </dsig:Transforms>
                        <dsig:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                        <dsig:DigestValue>Wj9Mk/JZYSj/oun9jvIh8UUg3esvigRvZiUX+i3/PIs=</dsig:DigestValue>
                    </dsig:Reference>
            </dsig:SignedInfo>
            <dsig:SignatureValue>YjRQvTacPUIL83QSUb5dQsDrfn+IrtgIIXjSp45l1n606Q2U6fw83O3Cw6O2gkDOZ5niC+kyI5OS
mET6QQ/+uaPtxPFVk7dFwluMK3rLKsiIUO68jIKO1TWxwT1jhpYo+og/gIPFQkE48GHC91gWfN6T
0senls89yDV+1ytKFiaXBqy/E0hkmxk13+fDLGEs1/C4pfwHiKf4aAtJmxsJ5f1PCZLk0ST1Hp6X
dqbcnU3XbqeskyPGca/iA3d7LrDddl96LkfBB62eNcojv0XwVFxCxfSaFjnLcYSLjNforZf1NdoW
zI9LioK6oIJwgNckhVU22dKXOcdacOYfbfdpgw==
</dsig:SignatureValue>
            <dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>
MIIFuDCCA6CgAwIBAgICEAMwDQYJKoZIhvcNAQELBQAwezELMAkGA1UEBhMCQ0Ex
FjAUBgNVBAgMDU5ldyBCcnVuc3dpY2sxHTAbBgNVBAoMFENyeXB0LU9wZW5TU0wt
VmVyaWZ5MTUwMwYDVQQDDCxDcnlwdC1PcGVuU1NMLVZlcmlmeSBTSEEtMjU2IElu
dGVybWVkaWF0ZSBDQTAeFw0yMTA3MDMyMTAyMjRaFw0zMTA3MDEyMTAyMjRaMGcx
CzAJBgNVBAYTAkNBMRYwFAYDVQQIDA1OZXcgQnJ1bnN3aWNrMRAwDgYDVQQHDAdN
b25jdG9uMRAwDgYDVQQKDAdYTUwtU2lnMRwwGgYDVQQDDBN4bWwtc2lnLmV4YW1w
bGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArkqxhCTOB2Xx
FxCNWJt0bLWRQva6qOAPKiqlLfgJjG+YY2JaPtpO7WNV5oVqv9F21V/wgOkcQTZZ
QQQl/L/eXlnFpJeSpF31dupLnzrBU29qWjedNCkj+y01sprJG+c++2d2jV8Qccp5
5SklALtXYZ3K5OfILy4dFEqUyW0/Bk7Y/PdrAacAazumdNW2nw/ajbiXbUfm55Qe
bQd/61emGettQBT9EUPOxMQrrtxHHxwyvrtsa9KyRPCamYEamOA0Al2Eya5dPWzE
bndbVpRx1jz8Ec6ANk8wJHTkggJOUXWem7HL4x8v9hEQeaHEy5CwxKzodDpV2bA/
Adr+NCYhsQIDAQABo4IBWDCCAVQwCQYDVR0TBAIwADARBglghkgBhvhCAQEEBAMC
BkAwMwYJYIZIAYb4QgENBCYWJE9wZW5TU0wgR2VuZXJhdGVkIFNlcnZlciBDZXJ0
aWZpY2F0ZTAdBgNVHQ4EFgQUDYY0sUvDD+ttN7MKzQzVgg25D94wgboGA1UdIwSB
sjCBr4AUzVMiKnV2P0l/W5nowtx2oIRM0S2hgZKkgY8wgYwxCzAJBgNVBAYTAkNB
MRYwFAYDVQQIDA1OZXcgQnJ1bnN3aWNrMRAwDgYDVQQHDAdNb25jdG9uMR0wGwYD
VQQKDBRDcnlwdC1PcGVuU1NMLVZlcmlmeTE0MDIGA1UEAwwrQ3J5cHQtT3BlblNT
TC1WZXJpZnkgU0hBLTI1NiBSb290IEF1dGhvcml0eYICEAAwDgYDVR0PAQH/BAQD
AgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqGSIb3DQEBCwUAA4ICAQAlDY7m
1wwRB/X8NSeQ/Hvxg9dG4OofLFaC4e7dlC5kOT/ZIHQ6NIdzkQ2yOY1piKKYEYuO
G/adtWAt8zRoejFob8W5aCA36uNoQLvdaMwXYNsJkzDNEmCB6vf3A28bVI+mlnt1
+h3f0bkwxwHP2qYL8RneCL65GG+SWXHIipS/ZA5225mmT1oLo9xKeGK6vBgsOUum
vxDgzmYyeGZYKpACWbOI7lR3C6PMR0oLKManLdb+ymngIk0bKB+Y2gr5cq/zURv8
casiikjZT3MycPRV1AfQ3MYuXg6z4izkcG1U98E9Hr5p1gFsITmaY0aeK01a6xhx
XkWKFTbraDn5ouTVMutW8xaVPU60zpYOcynxtRdgnYdmRR+c9dcD2xQmjtohuLxq
RASCBC9iO7qTYkQvNW+yb63xbPDG05nokAfXpbp5hYVU8FYZHi8qOPtiaWiN9wbt
ijsxDKZEcfiSGH5AEnkoaRCEqvbSNdtlbfYeDEnonsOZi9c+Kdl6A4PvOzTexwmi
KPVgT8evWpQbubENw66vUOTqgkI+Bhbn87e1VELNUy+Uwz2OOcLEVvNkx0owswrH
ujwb1+y1SYnlalLUt7PzEW85RNqVewGsHE8SD/1s70eYNYp7YJwLGPKJfyr3LvSl
0qRfrYNhlewPc1MSVx7IFCZ4Qg+GFhg8TnEELQ==
</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>
        </dsig:Signature></saml:Assertion>
<dsig:Signature>
            <dsig:SignedInfo xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                <dsig:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
                <dsig:Reference URI="#id-2806f1cc-9ec9-4b70-ae58-e252e58159f1">
                        <dsig:Transforms>
                            <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
                            <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </dsig:Transforms>
                        <dsig:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                        <dsig:DigestValue>CTLVgcRtdRyS0Xj6WtjfYrV3BZkwZFU2cjPXXQln7tI=</dsig:DigestValue>
                    </dsig:Reference>
            </dsig:SignedInfo>
            <dsig:SignatureValue>KCOW/WtwKZOrI6x+VzTKOyZ3cRJuUAPMYpsYiATzgCmfhymwORSytVmA+BJ+ZuFK1zxPk88UZJw0
0mj2KBVN635WkFj+zDci79qm6zTwxNRprE6XnF5tSgXQTJH7bS5nIu0jGbSiR6EJVpKS3usDZ8/Z
+tjkp2j/e2qeWDpXKUck8OCLclHkgzRa/sNXdGL20xc80qmVdkLCST+vUP92XUUlNM66EqvlOaHB
wmEgQwfgurTnQPOCdb+Ypm5fvJjYXFrDJDKXY2AHu0LF+fO39Trx2FWjZ27UPH9NW6KOtKrhRtlH
kV7ey4uddrz9t5Y08M12azJQIhgPMAszmVCXiw==
</dsig:SignatureValue>
            <dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>
MIIFuDCCA6CgAwIBAgICEAMwDQYJKoZIhvcNAQELBQAwezELMAkGA1UEBhMCQ0Ex
FjAUBgNVBAgMDU5ldyBCcnVuc3dpY2sxHTAbBgNVBAoMFENyeXB0LU9wZW5TU0wt
VmVyaWZ5MTUwMwYDVQQDDCxDcnlwdC1PcGVuU1NMLVZlcmlmeSBTSEEtMjU2IElu
dGVybWVkaWF0ZSBDQTAeFw0yMTA3MDMyMTAyMjRaFw0zMTA3MDEyMTAyMjRaMGcx
CzAJBgNVBAYTAkNBMRYwFAYDVQQIDA1OZXcgQnJ1bnN3aWNrMRAwDgYDVQQHDAdN
b25jdG9uMRAwDgYDVQQKDAdYTUwtU2lnMRwwGgYDVQQDDBN4bWwtc2lnLmV4YW1w
bGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArkqxhCTOB2Xx
FxCNWJt0bLWRQva6qOAPKiqlLfgJjG+YY2JaPtpO7WNV5oVqv9F21V/wgOkcQTZZ
QQQl/L/eXlnFpJeSpF31dupLnzrBU29qWjedNCkj+y01sprJG+c++2d2jV8Qccp5
5SklALtXYZ3K5OfILy4dFEqUyW0/Bk7Y/PdrAacAazumdNW2nw/ajbiXbUfm55Qe
bQd/61emGettQBT9EUPOxMQrrtxHHxwyvrtsa9KyRPCamYEamOA0Al2Eya5dPWzE
bndbVpRx1jz8Ec6ANk8wJHTkggJOUXWem7HL4x8v9hEQeaHEy5CwxKzodDpV2bA/
Adr+NCYhsQIDAQABo4IBWDCCAVQwCQYDVR0TBAIwADARBglghkgBhvhCAQEEBAMC
BkAwMwYJYIZIAYb4QgENBCYWJE9wZW5TU0wgR2VuZXJhdGVkIFNlcnZlciBDZXJ0
aWZpY2F0ZTAdBgNVHQ4EFgQUDYY0sUvDD+ttN7MKzQzVgg25D94wgboGA1UdIwSB
sjCBr4AUzVMiKnV2P0l/W5nowtx2oIRM0S2hgZKkgY8wgYwxCzAJBgNVBAYTAkNB
MRYwFAYDVQQIDA1OZXcgQnJ1bnN3aWNrMRAwDgYDVQQHDAdNb25jdG9uMR0wGwYD
VQQKDBRDcnlwdC1PcGVuU1NMLVZlcmlmeTE0MDIGA1UEAwwrQ3J5cHQtT3BlblNT
TC1WZXJpZnkgU0hBLTI1NiBSb290IEF1dGhvcml0eYICEAAwDgYDVR0PAQH/BAQD
AgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqGSIb3DQEBCwUAA4ICAQAlDY7m
1wwRB/X8NSeQ/Hvxg9dG4OofLFaC4e7dlC5kOT/ZIHQ6NIdzkQ2yOY1piKKYEYuO
G/adtWAt8zRoejFob8W5aCA36uNoQLvdaMwXYNsJkzDNEmCB6vf3A28bVI+mlnt1
+h3f0bkwxwHP2qYL8RneCL65GG+SWXHIipS/ZA5225mmT1oLo9xKeGK6vBgsOUum
vxDgzmYyeGZYKpACWbOI7lR3C6PMR0oLKManLdb+ymngIk0bKB+Y2gr5cq/zURv8
casiikjZT3MycPRV1AfQ3MYuXg6z4izkcG1U98E9Hr5p1gFsITmaY0aeK01a6xhx
XkWKFTbraDn5ouTVMutW8xaVPU60zpYOcynxtRdgnYdmRR+c9dcD2xQmjtohuLxq
RASCBC9iO7qTYkQvNW+yb63xbPDG05nokAfXpbp5hYVU8FYZHi8qOPtiaWiN9wbt
ijsxDKZEcfiSGH5AEnkoaRCEqvbSNdtlbfYeDEnonsOZi9c+Kdl6A4PvOzTexwmi
KPVgT8evWpQbubENw66vUOTqgkI+Bhbn87e1VELNUy+Uwz2OOcLEVvNkx0owswrH
ujwb1+y1SYnlalLUt7PzEW85RNqVewGsHE8SD/1s70eYNYp7YJwLGPKJfyr3LvSl
0qRfrYNhlewPc1MSVx7IFCZ4Qg+GFhg8TnEELQ==
</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>
        </dsig:Signature></samlp:Response>
XML_FILE

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');

is($assertion->in_response_to, 'NETSAML2_1d8748c413abe58635d3c8b53b79633a', 'In response to is correct');

is(scalar keys %{ $assertion->attributes }, 4, "Found four attributes");
is(scalar @{ $assertion->attributes->{EmailAddress} }, 1);
is(scalar @{ $assertion->attributes->{NickName} }, 1);
is(scalar @{ $assertion->attributes->{FirstName} }, 1);

is($assertion->session, 'bb6a1d05-b292-4a3c-acfa-b2d9101dbb97', 'Session ID is correct');
is($assertion->nameid, 'user@netsaml2.local.evil.com', "NameID properly ignored comments");
isnt($assertion->nameid, 'user@netsaml2.local', "NameID properly ignored comments");

cmp_deeply(
    $assertion->attributes,
    {
        EmailAddress => [qw(user@netsaml2.local.evil.com)],
        FirstName    => [qw(Tester)],
        NickName     => [Encode::decode("utf8", 'パスワードをお忘れの方')],
        saml_subject => [qw(43712857-1df8-4f6e-b476-a8fdc4446dd1)],
    },
    "Assertion attributes are ok"
);
is($assertion->audience, 'https://netsaml2-testapp.local', "Assertion audience is netsaml2-testapp.local");
is($assertion->valid('foo'),             0, "foo isn't a valid assertion");
is($assertion->valid('https://netsaml2-testapp.local'), 0, "https://netsaml2-testapp.local isn't valid either");
#
## fudge validity times to test valid()
$assertion->{not_before} = DateTime->now;
$assertion->{not_after} = DateTime->now->add(minutes => 15);
is($assertion->valid('https://netsaml2-testapp.local'), 1, "https://netsaml2-testapp.local is valid now - InResponseTo not Checked");
is($assertion->valid('https://netsaml2-testapp.local', 'NETSAML2_1d8748c413abe58635d3c8b53b79633a'), 1, ".https://netsaml2-testapp.local is valid now - InResponseTo Checked");
is($assertion->valid('https://netsaml2-testapp.local', 'N3k95Hg41WCHdwc9mqXyn'), 0, "Invalid InResponseTo Checked and failed");

$assertion->{not_before} = DateTime->now->add(minutes => 5);
is($assertion->valid('https://netsaml2-testapp.local'), 0, "and invalid again - InResponseTo not Checked");
is($assertion->valid('https://netsaml2-testapp.local', 'NETSAML2_1d8748c413abe58635d3c8b53b79633a'), 0, "and invalid again - InResponseTo Checked");
#
done_testing;
