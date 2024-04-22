use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use Sub::Override;

use Net::SAML2::Protocol::LogoutResponse;
use Net::SAML2::Protocol::Artifact;
use Net::SAML2::Protocol::Assertion;
use URN::OASIS::SAML2 qw(:urn);

my $artifact_assertion_response = << 'ASSERTION_RESPONSE';
<samlp:ArtifactResponse xmlns="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="ID_78cb9be7-12e9-4457-990f-b0ab4fb63f9f" InResponseTo="NETSAML2_7aaf00ca8438e4906f65659a6dd7f84b8a19aca8dc0916ea7066d7e6ab19a62f" IssueInstant="2023-01-29T16:21:09.254Z" Version="2.0"><saml:Issuer>https://keycloak.local:8443/realms/Foswiki</saml:Issuer><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"><dsig:SignedInfo><dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><dsig:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><dsig:Reference URI="#ID_78cb9be7-12e9-4457-990f-b0ab4fb63f9f"><dsig:Transforms><dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></dsig:Transforms><dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><dsig:DigestValue>xa6Re6R1tZRL0O2I41E4F75+pPw=</dsig:DigestValue></dsig:Reference></dsig:SignedInfo><dsig:SignatureValue>fnVIbQFRtlLPVasc5oDCM6DsX4wbgta747bVFolx/APfzTYfP2n3MhZVOqSH1E6B6lzYOWsp1YOn&#13;
ZKC4eQWtRMFui3jzHS3Py+L7Jj15z4sjP7wURLBhxAv4tkYxNK8BAka/JjaZOz1VbhcuYcSTzCCm&#13;
ypJaSLWIQTj+SgCJvsX22vJ71q1pRgfcSeD2bAIEVdqqCvCBpMoRMoMzAMQchJ7yertoQso/9pAV&#13;
LOu+fF4C1UARuKjzFdFT2tkUigW4LvAK4XaQzPRhHVjWO1z+t9XeA0qkMUMCMiSNzRSvQb3DB9XV&#13;
tmjFOE3ajs92hg65EC7ByJ8ze+wk41c5ua0xEA==</dsig:SignatureValue><dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>MIICnTCCAYUCBgGEmFcmeDANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdGb3N3aWtpMB4XDTIy&#13;
MTEyMTAzNTczOVoXDTMyMTEyMTAzNTkxOVowEjEQMA4GA1UEAwwHRm9zd2lraTCCASIwDQYJKoZI&#13;
hvcNAQEBBQADggEPADCCAQoCggEBAJeeWUPyhuxoA0S7tWF5eG18l5cSZYXjbH2eoa6bXNJB1h2L&#13;
1Bmi5a14DVSPQETeUo/l9yzOdpp23ngCvROue0uwg4fNTqdOECOYjIgFuDTwRAtvFoKXZ1He8AD6&#13;
OlgwP/k2ne85NxQ+rCt/bxrJ2b8J57J0FjphfHVJcgTZEu8fmahkO6sYYiURb65mVzR9I7Sq9W1t&#13;
DGrCIup7h9kYi+xDcAjVreZboYqpiL/ElqJGYkp12PXfx/RFsswu7ICCjjIK7WyuqvSrdzW0vHgL&#13;
ZmaVe+KzE80Ig3VAsO4lbCBs8JHS6CkmHc48kfiC2qmiBfE1WVA2tmiGSCo3URbg6VUCAwEAATAN&#13;
BgkqhkiG9w0BAQsFAAOCAQEAbridXRbw3WeKUyeR8o5IzdEtO8j+vw6jCd2lBHLEi2sPpHhi6+Lj&#13;
cQ+haqALCB2dknuBQHt3HBo/U9cRFBa5xA5z0Do06CsrZ2czks3icXYkCzVCOtCvbj/79Vo3JLoV&#13;
ifX+rLEYlxhKVaVhFslwSoS59kFwuMAo73szhW0C8HLtWDN0yrS/XDw1Nidesx+AmDEr/K5ofgKa&#13;
H/zExdQG7RcrAeHGswluWrEd43wLuX1UpIp6CLsrVSGwDQNCsgZATXbiyYS3RNhQeAW7hW9aJuG+&#13;
tqFxJ4u+6crHsA/FLZ2XVquRHx5dClGa9i9aPaK6Q7V9fo9KpgCBCAShpBabNA==</dsig:X509Certificate></dsig:X509Data><dsig:KeyValue><dsig:RSAKeyValue><dsig:Modulus>l55ZQ/KG7GgDRLu1YXl4bXyXlxJlheNsfZ6hrptc0kHWHYvUGaLlrXgNVI9ARN5Sj+X3LM52mnbe&#13;
eAK9E657S7CDh81Op04QI5iMiAW4NPBEC28WgpdnUd7wAPo6WDA/+Tad7zk3FD6sK39vGsnZvwnn&#13;
snQWOmF8dUlyBNkS7x+ZqGQ7qxhiJRFvrmZXNH0jtKr1bW0MasIi6nuH2RiL7ENwCNWt5luhiqmI&#13;
v8SWokZiSnXY9d/H9EWyzC7sgIKOMgrtbK6q9Kt3NbS8eAtmZpV74rMTzQiDdUCw7iVsIGzwkdLo&#13;
KSYdzjyR+ILaqaIF8TVZUDa2aIZIKjdRFuDpVQ==</dsig:Modulus><dsig:Exponent>AQAB</dsig:Exponent></dsig:RSAKeyValue></dsig:KeyValue></dsig:KeyInfo></dsig:Signature><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><samlp:Response Destination="https://netsaml2-testapp.local/consumer-artifact" ID="ID_31872488-8064-45c7-bfc2-7fc6646f6793" InResponseTo="NETSAML2_2b2bcaa750d745ed5ffec2e3cc3a905ab855de0f7970d9391427641a720e6a97" IssueInstant="2023-01-29T16:21:09.253Z" Version="2.0"><saml:Issuer>https://keycloak.local:8443/realms/Foswiki</saml:Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><saml:Assertion ID="ID_ef9c4328-63de-4d55-ae05-e5342e67f36c" IssueInstant="2023-01-29T16:21:09.253Z" Version="2.0"><saml:Issuer>https://keycloak.local:8443/realms/Foswiki</saml:Issuer><saml:Subject><saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">timlegge@cpan.org</saml:NameID><saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><saml:SubjectConfirmationData InResponseTo="NETSAML2_2b2bcaa750d745ed5ffec2e3cc3a905ab855de0f7970d9391427641a720e6a97" NotOnOrAfter="2023-01-29T16:26:07.253Z" Recipient="https://netsaml2-testapp.local/consumer-artifact"/></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore="2023-01-29T16:21:07.253Z" NotOnOrAfter="2023-01-29T16:22:07.253Z"><saml:AudienceRestriction><saml:Audience>https://netsaml2-testapp.local</saml:Audience></saml:AudienceRestriction></saml:Conditions><saml:AuthnStatement AuthnInstant="2023-01-29T16:21:09.253Z" SessionIndex="bb763071-a7c7-45e4-a2a6-d69b1c06a001::29499342-7453-4345-b702-68351fcad4f2" SessionNotOnOrAfter="2023-01-30T02:21:09.253Z"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement><saml:AttributeStatement><saml:Attribute FriendlyName="FirstName" Name="FirstName" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Timothy</saml:AttributeValue></saml:Attribute><saml:Attribute FriendlyName="surname" Name="urn:oid:2.5.4.4" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Legge</saml:AttributeValue></saml:Attribute><saml:Attribute FriendlyName="CN" Name="CN" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">keycloak.local</saml:AttributeValue></saml:Attribute><saml:Attribute FriendlyName="email" Name="EmailAddress" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">timlegge@cpan.org</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">manage-account-links</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">default-roles-foswiki</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">offline_access</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">view-profile</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">uma_authorization</saml:AttributeValue></saml:Attribute><saml:Attribute Name="Role" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"><saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">manage-account</saml:AttributeValue></saml:Attribute></saml:AttributeStatement></saml:Assertion></samlp:Response></samlp:ArtifactResponse>
ASSERTION_RESPONSE

my $artifact_logout_response = << 'LOGOUT_RESPONSE';
<samlp:ArtifactResponse xmlns="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="ID_7dd3a831-57e9-409e-873e-eb4730ed8392" InResponseTo="NETSAML2_209c37a48a23919f6de933486f0a03d9e8f9ccd8789503c86b446a16c96d3ce4" IssueInstant="2023-01-29T15:59:45.462Z" Version="2.0"><saml:Issuer>https://keycloak.local:8443/realms/Foswiki</saml:Issuer><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"><dsig:SignedInfo><dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><dsig:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><dsig:Reference URI="#ID_7dd3a831-57e9-409e-873e-eb4730ed8392"><dsig:Transforms><dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></dsig:Transforms><dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><dsig:DigestValue>pba2nAP9gZUz930g5BqIIXJ+t68=</dsig:DigestValue></dsig:Reference></dsig:SignedInfo><dsig:SignatureValue>Mr2D/azy1FP9dXgLi7ycFzkhdVQup2sr7Qt1bmDcH5ja3JEMeMjHsjFzaYcYN/k2tPIxT0FzNvzU&#13;
cClAeaHcn419fdNJXEX7dhcx36rLA4xKV8JHNuvjoKbb31D5DQAsE2YH4qqoy3SQr5FiLRfGdnTj&#13;
6F0CN73BjecaoxgiV+5ajS5YwHHDirolRbHQdWVC6KFqlfpqSv743bbZhBThjVBxeyKCpmFaGnZM&#13;
JM/UQbY7aPe1yqnbATvEcj+9N25Q7+RDNIxVnjXIq2FzNXE12PbUm/gMW1hBbGtH59CEvs0xOuB5&#13;
v+kSGB6yVS3Odz5m4wFvtK4ABuLMQmKqDb3TXw==</dsig:SignatureValue><dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>MIICnTCCAYUCBgGEmFcmeDANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdGb3N3aWtpMB4XDTIy&#13;
MTEyMTAzNTczOVoXDTMyMTEyMTAzNTkxOVowEjEQMA4GA1UEAwwHRm9zd2lraTCCASIwDQYJKoZI&#13;
hvcNAQEBBQADggEPADCCAQoCggEBAJeeWUPyhuxoA0S7tWF5eG18l5cSZYXjbH2eoa6bXNJB1h2L&#13;
1Bmi5a14DVSPQETeUo/l9yzOdpp23ngCvROue0uwg4fNTqdOECOYjIgFuDTwRAtvFoKXZ1He8AD6&#13;
OlgwP/k2ne85NxQ+rCt/bxrJ2b8J57J0FjphfHVJcgTZEu8fmahkO6sYYiURb65mVzR9I7Sq9W1t&#13;
DGrCIup7h9kYi+xDcAjVreZboYqpiL/ElqJGYkp12PXfx/RFsswu7ICCjjIK7WyuqvSrdzW0vHgL&#13;
ZmaVe+KzE80Ig3VAsO4lbCBs8JHS6CkmHc48kfiC2qmiBfE1WVA2tmiGSCo3URbg6VUCAwEAATAN&#13;
BgkqhkiG9w0BAQsFAAOCAQEAbridXRbw3WeKUyeR8o5IzdEtO8j+vw6jCd2lBHLEi2sPpHhi6+Lj&#13;
cQ+haqALCB2dknuBQHt3HBo/U9cRFBa5xA5z0Do06CsrZ2czks3icXYkCzVCOtCvbj/79Vo3JLoV&#13;
ifX+rLEYlxhKVaVhFslwSoS59kFwuMAo73szhW0C8HLtWDN0yrS/XDw1Nidesx+AmDEr/K5ofgKa&#13;
H/zExdQG7RcrAeHGswluWrEd43wLuX1UpIp6CLsrVSGwDQNCsgZATXbiyYS3RNhQeAW7hW9aJuG+&#13;
tqFxJ4u+6crHsA/FLZ2XVquRHx5dClGa9i9aPaK6Q7V9fo9KpgCBCAShpBabNA==</dsig:X509Certificate></dsig:X509Data><dsig:KeyValue><dsig:RSAKeyValue><dsig:Modulus>l55ZQ/KG7GgDRLu1YXl4bXyXlxJlheNsfZ6hrptc0kHWHYvUGaLlrXgNVI9ARN5Sj+X3LM52mnbe&#13;
eAK9E657S7CDh81Op04QI5iMiAW4NPBEC28WgpdnUd7wAPo6WDA/+Tad7zk3FD6sK39vGsnZvwnn&#13;
snQWOmF8dUlyBNkS7x+ZqGQ7qxhiJRFvrmZXNH0jtKr1bW0MasIi6nuH2RiL7ENwCNWt5luhiqmI&#13;
v8SWokZiSnXY9d/H9EWyzC7sgIKOMgrtbK6q9Kt3NbS8eAtmZpV74rMTzQiDdUCw7iVsIGzwkdLo&#13;
KSYdzjyR+ILaqaIF8TVZUDa2aIZIKjdRFuDpVQ==</dsig:Modulus><dsig:Exponent>AQAB</dsig:Exponent></dsig:RSAKeyValue></dsig:KeyValue></dsig:KeyInfo></dsig:Signature><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status><samlp:LogoutResponse Destination="https://netsaml2-testapp.local/sls-consumer-artifact" ID="ID_bfc25851-4da2-4420-8240-9103b77b12dc" InResponseTo="NETSAML2_0b499739aa1d76eb80093a068053b8fee62cade60f7dc27826d0f13b19cad16a" IssueInstant="2023-01-29T15:59:45.462Z" Version="2.0"><Issuer>https://keycloak.local:8443/realms/Foswiki</Issuer><samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status></samlp:LogoutResponse></samlp:ArtifactResponse>
LOGOUT_RESPONSE

my $override = Sub::Override->override(
    'Net::SAML2::Protocol::Assertion::valid' =>
        sub {
            my ($self, $audience, $in_response_to) = @_;

            return 0 unless defined $audience;
            return 0 unless($audience eq $self->audience);

            return 0 unless !defined $in_response_to
                or $in_response_to eq $self->in_response_to;

            my $now = $self->not_before->add(seconds => 10);

            # not_before is "NotBefore" element - exact match is ok
            # not_after is "NotOnOrAfter" element - exact match is *not* ok
            return 0 unless DateTime::->compare($now,             $self->not_before) > -1;
            return 0 unless DateTime::->compare($self->not_after, $now) > 0;

            return 1;
       }
);

###################################
# Assertion from ArtifactResponse #
###################################
my $assertion_artifact = Net::SAML2::Protocol::Artifact->new_from_xml(
    xml => $artifact_assertion_response,
);

isa_ok($assertion_artifact, "Net::SAML2::Protocol::Artifact");

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml => $assertion_artifact->response,
);

isa_ok($assertion, "Net::SAML2::Protocol::Assertion");

is($assertion->valid("https://netsaml2-testapp.local"), "1", "Assertion is Valid - ok");

is($assertion->in_response_to, 'NETSAML2_2b2bcaa750d745ed5ffec2e3cc3a905ab855de0f7970d9391427641a720e6a97', "Assertion InResponseTo - ok");

is($assertion->id, 'ID_ef9c4328-63de-4d55-ae05-e5342e67f36c', "Assertion ID - ok");

$assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml => $assertion_artifact->get_response(),
);

isa_ok($assertion, "Net::SAML2::Protocol::Assertion", "from get_response");

is($assertion->valid("https://netsaml2-testapp.local"), "1", "Assertion is Valid - ok");

is($assertion->in_response_to, 'NETSAML2_2b2bcaa750d745ed5ffec2e3cc3a905ab855de0f7970d9391427641a720e6a97', "Assertion InResponseTo - ok");

is($assertion->id, 'ID_ef9c4328-63de-4d55-ae05-e5342e67f36c', "Assertion ID - ok");

########################################
# LogoutResponse from ArtifactResponse #
########################################
my $logout_artifact = Net::SAML2::Protocol::Artifact->new_from_xml(
    xml => $artifact_logout_response,
);

isa_ok($logout_artifact, "Net::SAML2::Protocol::Artifact");

my $logout = Net::SAML2::Protocol::LogoutResponse->new_from_xml(
    xml => $logout_artifact->logout_response,
);

isa_ok($logout, "Net::SAML2::Protocol::LogoutResponse");

ok($logout->success(), "Logout Response has a Success");

is($logout->in_response_to, 'NETSAML2_0b499739aa1d76eb80093a068053b8fee62cade60f7dc27826d0f13b19cad16a', "Logout Response InResponseTo - ok");

{
  # TODO: Remove once response_to has been eradicated
  local $SIG{__WARN__} = sub { }; # Suppress the warning in the testsuite
  is($logout->response_to, $logout->in_response_to, ".. and old method still works");
}

is($logout->id, 'ID_bfc25851-4da2-4420-8240-9103b77b12dc', "Logout Response Id - ok");

$logout = Net::SAML2::Protocol::LogoutResponse->new_from_xml(
    xml => $logout_artifact->get_response(),
);

isa_ok($logout, "Net::SAML2::Protocol::LogoutResponse", "from get_response");

ok($logout->success(), "Logout Response has a Success");

is($logout->in_response_to, 'NETSAML2_0b499739aa1d76eb80093a068053b8fee62cade60f7dc27826d0f13b19cad16a', "Logout Response InResponseTo - ok");

done_testing;
