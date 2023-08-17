use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use MIME::Base64 qw/decode_base64/;

use Net::SAML2::Protocol::Assertion;

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

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');

is($assertion->{id},
    "s241001b6007d1700109a3e3bc4350ae5528ba9824",
    "Assertion id is as expected");

is($assertion->in_response_to, 'N3k95Hg41WCHdwc9mqXynLPhB');

is(scalar keys %{ $assertion->attributes }, 2);
is(scalar @{ $assertion->attributes->{EmailAddress} }, 1);
is(scalar @{ $assertion->attributes->{Phone2} }, 3);

is($assertion->session, 's2b087bdce06dbbf9cd4662af82b8b853d4d285c01', 'Session ID is correct');

is($assertion->nameid, 'nKdwzcgBYGt42xovLuctZ60tyafv', 'Name ID is correct');
is(
    $assertion->nameid_format,
    'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
    '.. and Name ID format is also correct'
);

cmp_deeply(
    $assertion->attributes,
    {
        EmailAddress => [qw(demo@sso.venda.com)],
        Phone2       => [qw(123456 234567 345678)]
    },
    "Assertion attributes are ok"
);

isa_ok($assertion->not_before, 'DateTime');
isa_ok($assertion->not_after,  'DateTime');

is($assertion->audience, 'http://ct.local', "Assertion audience is ct.local");
is($assertion->valid('foo'),             0, "foo isn't a valid assertion");
is($assertion->valid('http://ct.local'), 0, "ct.local isn't valid either");

# fudge validity times to test valid()
$assertion->{not_before} = DateTime->now;
$assertion->{not_after} = DateTime->now->add(minutes => 15);
is($assertion->valid('http://ct.local'), 1, "ct.local is valid now - InResponseTo not Checked");
is($assertion->valid('http://ct.local', 'N3k95Hg41WCHdwc9mqXynLPhB'), 1, "ct.local is valid now - InResponseTo Checked");
is($assertion->valid('http://ct.local', 'N3k95Hg41WCHdwc9mqXyn'), 0, "Invalid InResponseTo Checked and failed");

$assertion->{not_before} = DateTime->now->add(minutes => 5);
is($assertion->valid('http://ct.local'), 0, "and invalid again - InResponseTo not Checked");
is($assertion->valid('http://ct.local', 'N3k95Hg41WCHdwc9mqXynLPhB'), 0, "and invalid again - InResponseTo Checked");

is($assertion->authnstatement_authninstant,
    '2010-10-12T12:58:34Z',
    "AuthnStatement AuthnInstant is ok");
is($assertion->authnstatement_sessionindex,
    's2b087bdce06dbbf9cd4662af82b8b853d4d285c01',
    "AuthnStatement SessionIndex is ok");
is($assertion->subjectlocality_address,
    undef,
    "SubjectLocality Address is ok");
is($assertion->subjectlocality_dnsname,
    undef,
    "SubjectLocality DNSName is ok");
is($assertion->contextclass_authncontextclassref,
    'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
    "AuthnContext AuthnContextClassRef is ok");

my $assertion_b64 = <<'BASE64';
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c2FtbDJwOlJlc3BvbnNlIHhtbG5zOnNhbWwycD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnByb3RvY29sIiBEZXN0aW5hdGlvbj0iaHR0cHM6Ly9uZXRzYW1sMi10ZXN0YXBwLmxvY2FsL2NvbnN1bWVyLXBvc3QiIElEPSJfYjE2MGU3MTBlYzg2OGNiNzhlN2QzMDNiOGRiOWI1MzYiIEluUmVzcG9uc2VUbz0iTkVUU0FNTDJfNzQzNDIxZWY1YzkzMDIxODZkODA1MGM0YzViYWI3ZTc2YThiOGZkNGUzMjliMGY5YTM5YTE4MjM1Njc2MGRlMSIgSXNzdWVJbnN0YW50PSIyMDIzLTAxLTE0VDE0OjM3OjE1LjgxNFoiIFZlcnNpb249IjIuMCI+PHNhbWwyOklzc3VlciB4bWxuczpzYW1sMj0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmFzc2VydGlvbiI+aHR0cHM6Ly9pZHAuc2hpYmJvbGV0aC5sb2NhbC9pZHAvc2hpYmJvbGV0aDwvc2FtbDI6SXNzdWVyPjxkczpTaWduYXR1cmUgeG1sbnM6ZHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyMiPjxkczpTaWduZWRJbmZvPjxkczpDYW5vbmljYWxpemF0aW9uTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PGRzOlNpZ25hdHVyZU1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMDQveG1sZHNpZy1tb3JlI3JzYS1zaGEyNTYiLz48ZHM6UmVmZXJlbmNlIFVSST0iI19iMTYwZTcxMGVjODY4Y2I3OGU3ZDMwM2I4ZGI5YjUzNiI+PGRzOlRyYW5zZm9ybXM+PGRzOlRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNlbnZlbG9wZWQtc2lnbmF0dXJlIi8+PGRzOlRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyIvPjwvZHM6VHJhbnNmb3Jtcz48ZHM6RGlnZXN0TWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxlbmMjc2hhMjU2Ii8+PGRzOkRpZ2VzdFZhbHVlPmNmUWdybXltUWxsangrNitYS2dFVFJLck1yVjBnZmEya2JVSmtWdmJhMUU9PC9kczpEaWdlc3RWYWx1ZT48L2RzOlJlZmVyZW5jZT48L2RzOlNpZ25lZEluZm8+PGRzOlNpZ25hdHVyZVZhbHVlPkNLQk5RMFJpK2RZdFVmclUrdWhQSHNHYnBKc1h6VmUwSkFrbTJoRVF6R2NTWUdMcy9xTGdBK1NkQnFmaWtPQUthSm9YOENNOGt2WmhwenJpN1IrcFRVUU13dlZCTHFiYkJ0Mm9TaWZ5VFhuNEk5TEN3QWxOWHZmTCtZWGRmRGQ1dGtMcU8yMTNEWUlCcjdXS1NWRk9kZmNpa3NLZmlXUk1QM1FUL3F2Y2FlNktPN1U4TmpxREtScytWMlRaS0ErVHk0SWRjTHpzV3F3eWZEWWhKd0RDaEdsZm5hMDZZVjVmWWZMZnlCek1TNUU3MzU3MEt1Nm5jSDI3bEdIakdOcU1xVGg4VmZUM2FlVkNST3JCMkpEZ0pJZnlXaXZSWS9HaGk3TDBZUkl1ZldxbjRZdWZPMEZESndITXVMdG1FcDVaTmo1ZzdKcGZzc1F4OWRDZmN0b0dzMjcvM2tqZUhVVHJ2RVFoUTR3ZFdqMGVFZnltczVHTWpaYjlaSDk1RU9wQ1MzejhNaFBkL0ZpZFNSUUhCb3lOdFVjczhBQ3djZ0UyRTJFS3REWThhemJuRityQm9SZ2FYa29LcGlPa0ptVFh1bzFjR3ZVTXZXbkNoWTJ2NjBsWWZMVy85S1lrUjdKUEpHVFVzZEZCaFpCUGhaK2Vwa0hNUDlKekNEeGIrOWM1PC9kczpTaWduYXR1cmVWYWx1ZT48ZHM6S2V5SW5mbz48ZHM6WDUwOURhdGE+PGRzOlg1MDlDZXJ0aWZpY2F0ZT5NSUlFT3pDQ0FxT2dBd0lCQWdJVVUyZnluVVFaUytzWFJxajBPYzRZZ0Y0bUlPb3dEUVlKS29aSWh2Y05BUUVMQlFBd0h6RWRNQnNHCkExVUVBd3dVYVdSd0xuTm9hV0ppYjJ4bGRHZ3ViRzlqWVd3d0hoY05Nakl4TWpJMU1qSXpNakE0V2hjTk5ESXhNakkxTWpJek1qQTQKV2pBZk1SMHdHd1lEVlFRRERCUnBaSEF1YzJocFltSnZiR1YwYUM1c2IyTmhiRENDQWFJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dHUApBRENDQVlvQ2dnR0JBS3YxY0hyNjJ0MUtON0NNNnBCaTRFNzhGN2Rqa08zQVNRalA1c21QdVppc0I0S1FRL29NS05jSjBCUkoyZjJtCjVLTlJqOFJuVDJuckQxeWNod1lxdGJUQWZRZGZVTWMrclZkaGc4Rm5zTi9lNDFmOFhjQmg1Zjc0dm50OUFjSGVDU1YvR0dsZGUvTUkKcHpsN2ZTeUh6TTlCNUJlWnBWOUl2YVg3NWR5ZVdwSEpPNjR6OVF2WWZMTTNackJHdWJLYVVES0UrNDJkcE9najdIUW83TmNwT2VEbwo2bG1oYVVzZUFIeDZqdUw2M0lYV3lqS0dLbFVoYzd5WW8rQWx1KzlWY2ZXSDRPL1VUNTlsenphakZkTXhiZGtxci9GUDJMVEtXWXBvClRlOWZ4elRwaGNUTnlscnY4WHlodEZGcVA1NzJ4ODVIcWJMeDN3eVV4dks3QTZYd0VEUW5pTWF0RW9IUnA2MjBVZis0WjFSWllhVXkKS1JtV2lsT2NNVG9YTU94Qng2OHkvejdPck9ZTEZqYml4WmVlajd0bFZFTXo3cHdVTDdJL2RaQTQvU0lGeVVFUGRqOHRIdzMxM0lIRAowME5NWkJmcS8xdTQxTEJzWWJaMmI4WXpSYzZmaHpxS3IrU2dSMWVxa09lUE5ZSEVOQTQ0Tm5XdFJyT1FQSkhkeEt4ekRRSURBUUFCCm8yOHdiVEFkQmdOVkhRNEVGZ1FVaGx2NDl5M2VWeXlFUXM0ZkZvU2FpNTIvSU53d1RBWURWUjBSQkVVd1E0SVVhV1J3TG5Ob2FXSmkKYjJ4bGRHZ3ViRzlqWVd5R0syaDBkSEJ6T2k4dmFXUndMbk5vYVdKaWIyeGxkR2d1Ykc5allXd3ZhV1J3TDNOb2FXSmliMnhsZEdndwpEUVlKS29aSWh2Y05BUUVMQlFBRGdnR0JBS1dXZXhSUGczV01lMG02djlKa0prWDNsdVBRdlNZNU1KbXczMm9nRU1RSmlhUmEzSlpUCll1TDV6NXplQmhpZFRRK0laUWJ0MmJpNm13NU15U2kvSk11aVc2OU45c2gyOElnY3ZHU1k3c1NyeTVIVnIycUVCeWQwUE1WbTZ4ZXoKcHVMOW1IRDUwQWxmQzVod1cxOWM0QzJIdmpMcWN6NzlYS3RMMDlGZDhRTGJqYzF2TTlFa3B0MTVINTVLenNGUzVHYlhBVWpaWWh6RwpJVzZ4V29HUjIya2QrZEliUDdsNTVMRDhMZHI4ZkpMZEZkRURBWjdGcHhzWkNJZWsrNWJLclBSdjc1c2VhRTJoeE8vWitUdUJTdU1tCjlxMUxoSFJVUVV5OUNLQUV3NGZGRnFlU1RnL05udzNsbm1BRi9UMDBBNWVLQ1c0dWsxVmVUT1U2NXl3dnhHeU9tME9VZmtPVHFzUVIKOHRxei80RlkrcUpJa3NmMFpwQ1p6dEgrN2pxUmR2OG5RN2xJbGVldFVhbVBlMmhCL2hPUzkreHJBRGM0YmQ1M2IxdnMvVXp4WlBoSApXUnRWLzEwMmU3U0xJVEJsbDViVi9jTlBFaUZ6WEE5V2VXR1RvUDQrUW5ZQmRhby9BbFBob2tISGlkeXpHbmdUQWd1WHg4NGkwOCtGCmUra01xUT09PC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpTaWduYXR1cmU+PHNhbWwycDpTdGF0dXM+PHNhbWwycDpTdGF0dXNDb2RlIFZhbHVlPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6c3RhdHVzOlN1Y2Nlc3MiLz48L3NhbWwycDpTdGF0dXM+PHNhbWwyOkFzc2VydGlvbiB4bWxuczpzYW1sMj0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmFzc2VydGlvbiIgSUQ9Il82MWYzNzc3MTdjYWFkODdjZTJhZjBlNzk0NmNiOTdiMSIgSXNzdWVJbnN0YW50PSIyMDIzLTAxLTE0VDE0OjM3OjE1LjgxNFoiIFZlcnNpb249IjIuMCI+PHNhbWwyOklzc3Vlcj5odHRwczovL2lkcC5zaGliYm9sZXRoLmxvY2FsL2lkcC9zaGliYm9sZXRoPC9zYW1sMjpJc3N1ZXI+PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+PGRzOlNpZ25lZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48ZHM6U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8wNC94bWxkc2lnLW1vcmUjcnNhLXNoYTI1NiIvPjxkczpSZWZlcmVuY2UgVVJJPSIjXzYxZjM3NzcxN2NhYWQ4N2NlMmFmMGU3OTQ2Y2I5N2IxIj48ZHM6VHJhbnNmb3Jtcz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI2VudmVsb3BlZC1zaWduYXR1cmUiLz48ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8+PC9kczpUcmFuc2Zvcm1zPjxkczpEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGVuYyNzaGEyNTYiLz48ZHM6RGlnZXN0VmFsdWU+TXdCRkxzMzRZWWtNUmUzcTFEa1dnTWpxaTZWOGJIYlQzSkNUZnh5WkxKaz08L2RzOkRpZ2VzdFZhbHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+b3FldklBRW5XTFF3U1p4OGh4aVNBcE5CVnJXWkxvRjFaNEtPVFJidk9HZFl2Z3F3N21lQnZkb1JVbEd1cHkzQy9qbjBVUVBCNVpTb1VXd1BnZWJMbUY1T2F5V0tBY0M2TVlvUStadHRxKzRrT1RKK0RLUGFLTzJmRXNDekNTK0hYOGFjK0x1YWpIZkt2cXRkMW1LUDlVMVRRNjNaMWpvRG8ySDFFWE1RZE9ablJ3V1hnS0ZlWEFXUEphYjB2ZnZWZllhdVZVcm4xWkMyMFFhTkx6QmpSREMwZDZsb1hMM2c3Q1R5L1lOZjJtSk5jUmpXRjRFUjRjcU9kVXdEZHRCZ1hWRkdqUXMzNDVySzMvb044bE81VDdUaW1nbDFhTVB4Q29mK0VpdnNXamtiaUF4VHM5TTA1UUVXUmovQld6S0dZR3l1OXNyRFpNaWQrWjVCYWNDUUl6RloxLzhrS0dJNitVWVZEeGFVQ0xUOWFRb3c0bEV1VDEwazJsNExYcWphWEEveW1PaWg0bklLSjFBc0dIMTNVTXVsNEJPRXlMTzVBRkFYejU3SDNveHJkbHZXN0NhU3dieTB5aHh5VGNLNTRWb0wybEMwaEZhejlYTHZzaDFqU0h3eVpmTis2M1ZCdTh3NTBTNWVnbjRlQVlCZXpZTHd6THVrSFhSd0lhekM8L2RzOlNpZ25hdHVyZVZhbHVlPjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUVPekNDQXFPZ0F3SUJBZ0lVVTJmeW5VUVpTK3NYUnFqME9jNFlnRjRtSU9vd0RRWUpLb1pJaHZjTkFRRUxCUUF3SHpFZE1Cc0cKQTFVRUF3d1VhV1J3TG5Ob2FXSmliMnhsZEdndWJHOWpZV3d3SGhjTk1qSXhNakkxTWpJek1qQTRXaGNOTkRJeE1qSTFNakl6TWpBNApXakFmTVIwd0d3WURWUVFEREJScFpIQXVjMmhwWW1KdmJHVjBhQzVzYjJOaGJEQ0NBYUl3RFFZSktvWklodmNOQVFFQkJRQURnZ0dQCkFEQ0NBWW9DZ2dHQkFLdjFjSHI2MnQxS043Q002cEJpNEU3OEY3ZGprTzNBU1FqUDVzbVB1WmlzQjRLUVEvb01LTmNKMEJSSjJmMm0KNUtOUmo4Um5UMm5yRDF5Y2h3WXF0YlRBZlFkZlVNYytyVmRoZzhGbnNOL2U0MWY4WGNCaDVmNzR2bnQ5QWNIZUNTVi9HR2xkZS9NSQpwemw3ZlN5SHpNOUI1QmVacFY5SXZhWDc1ZHllV3BISk82NHo5UXZZZkxNM1pyQkd1YkthVURLRSs0MmRwT2dqN0hRbzdOY3BPZURvCjZsbWhhVXNlQUh4Nmp1TDYzSVhXeWpLR0tsVWhjN3lZbytBbHUrOVZjZldINE8vVVQ1OWx6emFqRmRNeGJka3FyL0ZQMkxUS1dZcG8KVGU5Znh6VHBoY1ROeWxydjhYeWh0RkZxUDU3Mng4NUhxYkx4M3d5VXh2SzdBNlh3RURRbmlNYXRFb0hScDYyMFVmKzRaMVJaWWFVeQpLUm1XaWxPY01Ub1hNT3hCeDY4eS96N09yT1lMRmpiaXhaZWVqN3RsVkVNejdwd1VMN0kvZFpBNC9TSUZ5VUVQZGo4dEh3MzEzSUhECjAwTk1aQmZxLzF1NDFMQnNZYloyYjhZelJjNmZoenFLcitTZ1IxZXFrT2VQTllIRU5BNDRObld0UnJPUVBKSGR4S3h6RFFJREFRQUIKbzI4d2JUQWRCZ05WSFE0RUZnUVVobHY0OXkzZVZ5eUVRczRmRm9TYWk1Mi9JTnd3VEFZRFZSMFJCRVV3UTRJVWFXUndMbk5vYVdKaQpiMnhsZEdndWJHOWpZV3lHSzJoMGRIQnpPaTh2YVdSd0xuTm9hV0ppYjJ4bGRHZ3ViRzlqWVd3dmFXUndMM05vYVdKaWIyeGxkR2d3CkRRWUpLb1pJaHZjTkFRRUxCUUFEZ2dHQkFLV1dleFJQZzNXTWUwbTZ2OUprSmtYM2x1UFF2U1k1TUptdzMyb2dFTVFKaWFSYTNKWlQKWXVMNXo1emVCaGlkVFErSVpRYnQyYmk2bXc1TXlTaS9KTXVpVzY5TjlzaDI4SWdjdkdTWTdzU3J5NUhWcjJxRUJ5ZDBQTVZtNnhlegpwdUw5bUhENTBBbGZDNWh3VzE5YzRDMkh2akxxY3o3OVhLdEwwOUZkOFFMYmpjMXZNOUVrcHQxNUg1NUt6c0ZTNUdiWEFValpZaHpHCklXNnhXb0dSMjJrZCtkSWJQN2w1NUxEOExkcjhmSkxkRmRFREFaN0ZweHNaQ0llays1YktyUFJ2NzVzZWFFMmh4Ty9aK1R1QlN1TW0KOXExTGhIUlVRVXk5Q0tBRXc0ZkZGcWVTVGcvTm53M2xubUFGL1QwMEE1ZUtDVzR1azFWZVRPVTY1eXd2eEd5T20wT1Vma09UcXNRUgo4dHF6LzRGWStxSklrc2YwWnBDWnp0SCs3anFSZHY4blE3bElsZWV0VWFtUGUyaEIvaE9TOSt4ckFEYzRiZDUzYjF2cy9VenhaUGhICldSdFYvMTAyZTdTTElUQmxsNWJWL2NOUEVpRnpYQTlXZVdHVG9QNCtRbllCZGFvL0FsUGhva0hIaWR5ekduZ1RBZ3VYeDg0aTA4K0YKZStrTXFRPT08L2RzOlg1MDlDZXJ0aWZpY2F0ZT48L2RzOlg1MDlEYXRhPjwvZHM6S2V5SW5mbz48L2RzOlNpZ25hdHVyZT48c2FtbDI6U3ViamVjdD48c2FtbDI6TmFtZUlEIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOm5hbWVpZC1mb3JtYXQ6cGVyc2lzdGVudCIgTmFtZVF1YWxpZmllcj0iaHR0cHM6Ly9pZHAuc2hpYmJvbGV0aC5sb2NhbC9pZHAvc2hpYmJvbGV0aCIgU1BOYW1lUXVhbGlmaWVyPSJodHRwczovL25ldHNhbWwyLXRlc3RhcHAubG9jYWwiIHhtbG5zOnNhbWwyPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIj43VlRCSDRXVlhNQ1lPS1dYS1ZBRkpMTVRNR05JSUdNWDwvc2FtbDI6TmFtZUlEPjxzYW1sMjpTdWJqZWN0Q29uZmlybWF0aW9uIE1ldGhvZD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmNtOmJlYXJlciI+PHNhbWwyOlN1YmplY3RDb25maXJtYXRpb25EYXRhIEFkZHJlc3M9IjE5Mi4xNjguMTIyLjEiIEluUmVzcG9uc2VUbz0iTkVUU0FNTDJfNzQzNDIxZWY1YzkzMDIxODZkODA1MGM0YzViYWI3ZTc2YThiOGZkNGUzMjliMGY5YTM5YTE4MjM1Njc2MGRlMSIgTm90T25PckFmdGVyPSIyMDIzLTAxLTE0VDE0OjQyOjE1LjgyNloiIFJlY2lwaWVudD0iaHR0cHM6Ly9uZXRzYW1sMi10ZXN0YXBwLmxvY2FsL2NvbnN1bWVyLXBvc3QiLz48L3NhbWwyOlN1YmplY3RDb25maXJtYXRpb24+PC9zYW1sMjpTdWJqZWN0PjxzYW1sMjpDb25kaXRpb25zIE5vdEJlZm9yZT0iMjAyMy0wMS0xNFQxNDozNzoxNS44MTRaIiBOb3RPbk9yQWZ0ZXI9IjIwMjMtMDEtMTRUMTQ6NDI6MTUuODE0WiI+PHNhbWwyOkF1ZGllbmNlUmVzdHJpY3Rpb24+PHNhbWwyOkF1ZGllbmNlPmh0dHBzOi8vbmV0c2FtbDItdGVzdGFwcC5sb2NhbDwvc2FtbDI6QXVkaWVuY2U+PC9zYW1sMjpBdWRpZW5jZVJlc3RyaWN0aW9uPjwvc2FtbDI6Q29uZGl0aW9ucz48c2FtbDI6QXV0aG5TdGF0ZW1lbnQgQXV0aG5JbnN0YW50PSIyMDIzLTAxLTE0VDE0OjM3OjE1Ljc4MVoiIFNlc3Npb25JbmRleD0iXzEyMWNlZjU0MTkxZDU3ZjkwNzUzNjE5ZmY4MTg1NmJkIj48c2FtbDI6U3ViamVjdExvY2FsaXR5IEFkZHJlc3M9IjE5Mi4xNjguMTIyLjEiLz48c2FtbDI6QXV0aG5Db250ZXh0PjxzYW1sMjpBdXRobkNvbnRleHRDbGFzc1JlZj51cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YWM6Y2xhc3NlczpQYXNzd29yZFByb3RlY3RlZFRyYW5zcG9ydDwvc2FtbDI6QXV0aG5Db250ZXh0Q2xhc3NSZWY+PC9zYW1sMjpBdXRobkNvbnRleHQ+PC9zYW1sMjpBdXRoblN0YXRlbWVudD48c2FtbDI6QXR0cmlidXRlU3RhdGVtZW50PjxzYW1sMjpBdHRyaWJ1dGUgRnJpZW5kbHlOYW1lPSJzY2hhY0hvbWVPcmdhbml6YXRpb24iIE5hbWU9InVybjpvaWQ6MS4zLjYuMS40LjEuMjUxNzguMS4yLjkiIE5hbWVGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphdHRybmFtZS1mb3JtYXQ6dXJpIj48c2FtbDI6QXR0cmlidXRlVmFsdWU+c2hpYmJvbGV0aC5sb2NhbDwvc2FtbDI6QXR0cmlidXRlVmFsdWU+PC9zYW1sMjpBdHRyaWJ1dGU+PC9zYW1sMjpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PC9zYW1sMjpBc3NlcnRpb24+PC9zYW1sMnA6UmVzcG9uc2U+
BASE64

$xml = decode_base64($assertion_b64);
$assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');

is($assertion->nameid_name_qualifier,
    "https://idp.shibboleth.local/idp/shibboleth",
    "nameid_name_qualifier is ok");
is($assertion->nameid_sp_name_qualifier,
    "https://netsaml2-testapp.local",
    "nameid_sp_name_qualifier is ok");
is($assertion->nameid_sp_provided_id,
    undef,
    "nameid_sp_provided_id undefined as expected");

is($assertion->authnstatement_authninstant,
    '2023-01-14T14:37:15.781Z',
    "AuthnStatement AuthnInstant is ok");
is($assertion->authnstatement_sessionindex,
    '_121cef54191d57f90753619ff81856bd',
    "AuthnStatement SessionIndex is ok");
is($assertion->subjectlocality_address,
    '192.168.122.1',
    "SubjectLocality Address is ok");
is($assertion->subjectlocality_dnsname,
    undef,
    "SubjectLocality DNSName is ok");
is($assertion->contextclass_authncontextclassref,
    'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
    "AuthnContext AuthnContextClassRef is ok");

is($assertion->id,
    "_61f377717caad87ce2af0e7946cb97b1",
    "Assertion id is as expected");

lives_ok(
    sub {
       my  $xml = path('t/data/eherkenning-assertion.xml')->slurp;
       $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
    },
    "Correct parsing of dates"
);

isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');
isa_ok($assertion->not_before, "DateTime", "not before is correct");
isa_ok($assertion->not_after, "DateTime", "... and so it not after");

is($assertion->not_before, "2020-06-02T11:48:07", "... and the correct not_before");
is($assertion->not_after, "2020-06-02T11:53:07", "... and the correct not_after");

lives_ok(
    sub {
       my  $xml = path('t/data/saml-adfs-plain.xml')->slurp;
       $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
    },
    "Correct parsing of plain ADFS"
);

lives_ok(
    sub {
       my  $xml = path('t/data/failed-assertion.xml')->slurp;
       $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
    },
    "Correct parsing of failed assertion"
);

ok(!$assertion->success, ".. not a success");
is(
    $assertion->response_status,
    "main status",
    "... and the status also indicates not a success"
);
is(
    $assertion->response_substatus,
    "sub status",
    "... and the sub status yay"
);


{
    my $xml = path('t/data/digid-live.xml')->slurp;
    my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(xml => $xml);
    isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');
}

is($assertion->authnstatement_authninstant,
    '2018-07-25T07:54:35.599Z',
    "AuthnStatement AuthnInstant is ok");
is($assertion->authnstatement_sessionindex,
    undef,
    "AuthnStatement SessionIndex is ok");
is($assertion->subjectlocality_address,
    undef,
    "SubjectLocality Address is ok");
is($assertion->subjectlocality_dnsname,
    undef,
    "SubjectLocality DNSName is ok");
is($assertion->contextclass_authncontextclassref,
    'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport',
    "AuthnContext AuthnContextClassRef is ok");

done_testing;
