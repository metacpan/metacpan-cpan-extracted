use Test::More;
use Net::SAML2;

my $xml = <<XML;
<?xml version="1.0"?>
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="s29e656961dc650775c103fddadba836256cc3eb7d" InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" Version="2.0" IssueInstant="2010-10-12T14:49:27Z" Destination="http://ct.local/saml/consumer-post">
  <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">http://sso.dev.venda.com/opensso</saml:Issuer>
  <samlp:Status xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">
    <samlp:StatusCode xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="s241001b6007d1700109a3e3bc4350ae5528ba9824" IssueInstant="2010-10-12T14:49:27Z" Version="2.0">
    <saml:Issuer>http://sso.dev.venda.com/opensso</saml:Issuer>
    <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
      <ds:SignedInfo>
        <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
        <ds:Reference URI="#s241001b6007d1700109a3e3bc4350ae5528ba9824">
          <ds:Transforms>
            <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
            <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
          </ds:Transforms>
          <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
          <ds:DigestValue>1CCTfUP/Sbihuz4HCySlSizG9+o=</ds:DigestValue>
        </ds:Reference>
      </ds:SignedInfo>
      <ds:SignatureValue>lHH8QBcAievrgDYmYXXk+QnWC/ybLYcbIZPEs06rEi7wE9Iwb96UxPM8zY24SSJ9CPZdZqyNsyIu9Ww+4dq7RcUbE9dBCKwAZjz/ze6jPTlEZPdG1H+g+c8HnC9mNTI1g4WDS8zBmSbBbYBEPiuVxHn245JaUrTRjoLE0Xr4EoY=</ds:SignatureValue>
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>MIIDDDCCAfSgAwIBAgIBBDANBgkqhkiG9w0BAQUFADA3MQswCQYDVQQGEwJVUzEOMAwGA1UECgwFbG9jYWwxCzAJBgNVBAsMAmN0MQswCQYDVQQDDAJDQTAeFw0xMDEwMDYxNDE5MDJaFw0xMTEwMDYxNDE5MDJaMGMxCzAJBgNVBAYTAkdCMQ8wDQYDVQQIEwZMb25kb24xDzANBgNVBAcTBkxvbmRvbjEOMAwGA1UEChMFVmVuZGExDDAKBgNVBAsTA1NTTzEUMBIGA1UEAxMLUlNBIE9wZW5TU08wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALatk5hsXZA1BVxgFmWsAHna/ok3wMIYAtf2S4pTWlhgYEEtz8btVPzOxLQ4eu6zAQHoPvOuZf0/LzQuhDgHVxX2x0BS/f5CfEC1Tx+gcSlINKz5pc1eylERMszXHrgJEqc5qJL/hqizrPQSTa5c4P1tOApUGmr5ri3GWs+j/OQhAgMBAAGjezB5MAkGA1UdEwQCMAAwLAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJhdGVkIENlcnRpZmljYXRlMB0GA1UdDgQWBBTJjwYYJePNfPQLlfplEcTJjF4NNzAfBgNVHSMEGDAWgBTWcCDL1HYlBpul6nAYYaX4JGy0FDANBgkqhkiG9w0BAQUFAAOCAQEAK37Jlh5FxY4Zzph9Q2lkPwBQpHqSM7WeWjOMlQo2cP3oPpbPMohmZwQncNOdHgxERqJ4C4c+olRwFxxA7D/S90emxn9c/dyv3zQIJtNwguhcEX35MaqEFUGvbqnmJukEzdbJm4FU2FC0qGni7Jkvx/bCmS2xvdf71sR2HKSzqmUHys4PAHJhFCVdQXfROlO+964Oxab/HzFUwDCf0wzJVksEB4DhP2sJtUIBJTpwofywMX5qLQuM6qPUJ/lRqpaxPOweKlkC5ndFnPtChc0+ZsJI3sBttz+07qyeZJJ8QNx9pRjKr9G8jtj5lXX+BOWizUt7QBTYNFQgWibMs3Ekmg==</ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </ds:Signature>
    <saml:Subject>
      <saml:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" NameQualifier="http://sso.dev.venda.com/opensso">nKdwzcgBYGt42xovLuctZ60tyafv</saml:NameID>
      <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
        <saml:SubjectConfirmationData InResponseTo="N3k95Hg41WCHdwc9mqXynLPhB" NotOnOrAfter="2010-10-12T14:59:27Z" Recipient="http://ct.local/saml/consumer-post"/>
      </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions NotBefore="2010-10-12T14:39:27Z" NotOnOrAfter="2010-10-12T14:59:27Z">
      <saml:AudienceRestriction>
        <saml:Audience>http://ct.local</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement AuthnInstant="2010-10-12T12:58:34Z" SessionIndex="s2b087bdce06dbbf9cd4662af82b8b853d4d285c01">
      <saml:AuthnContext>
        <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef>
      </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
      <saml:Attribute Name="Phone2">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">123456</saml:AttributeValue>
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">234567</saml:AttributeValue>
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">345678</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="EmailAddress">
        <saml:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">demo&#64;sso.venda.com</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
XML

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
        xml => $xml
);
ok($assertion);

is($assertion->session, 's2b087bdce06dbbf9cd4662af82b8b853d4d285c01');
is($assertion->nameid,  'nKdwzcgBYGt42xovLuctZ60tyafv');

is(scalar keys %{ $assertion->attributes }, 2);
is(scalar @{ $assertion->attributes->{EmailAddress} }, 1);
is(scalar @{ $assertion->attributes->{Phone2} }, 3);

is($assertion->attributes->{EmailAddress}->[0], 'demo@sso.venda.com');
is($assertion->attributes->{Phone2}->[0], '123456');
is($assertion->attributes->{Phone2}->[1], '234567');
is($assertion->attributes->{Phone2}->[2], '345678');

isa_ok($assertion->not_before, 'DateTime');
isa_ok($assertion->not_after,  'DateTime');
is($assertion->audience, 'http://ct.local');
is($assertion->valid('foo'), 0);
is($assertion->valid('http://ct.local'), 0);

# fudge validity times to test valid()
$assertion->{not_before} = DateTime->now;
$assertion->{not_after} = DateTime->now->add( minutes => 15);
is($assertion->valid('http://ct.local'), 1);

$assertion->{not_before} = DateTime->now->add( minutes => 5 );
is($assertion->valid('http://ct.local'), 0);

done_testing;
