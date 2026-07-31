use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Object::Response;
use URN::OASIS::SAML2 qw(STATUS_RESPONDER STATUS_AUTH_FAILED);

sub get_object {
  my $xml = path(shift)->slurp;
  my $destination = shift;
  my $response = Net::SAML2::Object::Response->new_from_xml(xml => $xml,
                    require_signed_response => 0,
                    insecure_trust_embedded_cert  => 1,
                    defined $destination ? (destination => $destination) : (),
                );
  isa_ok($response, 'Net::SAML2::Object::Response');
  return $response;
}

{
  my $response = get_object('t/data/digid-anul-artifact-response.xml');
  ok(!$response->has_assertions, "We don't have an assertion");
  ok(!$response->success, "Unsuccessful response");
  is($response->status, STATUS_RESPONDER(), "... because its a status:Responder");
  is($response->substatus, STATUS_AUTH_FAILED(), "... and substatus is also correct");
}


{
  throws_ok(sub{get_object('t/data/eherkenning-assertion.xml', 'INCORRECT_DESTINATION');},
      qr/Response Destination \(https:\/\/test.zaaksysteem.nl\/auth\/saml\/consumer-post\) does not match expected value \(INCORRECT_DESTINATION\)/, "Incorrect Destination fails as expected");
  lives_ok(sub{get_object('t/data/eherkenning-assertion.xml', 'https://test.zaaksysteem.nl/auth/saml/consumer-post');},
      "correct Destination lives as expected");
  my $response = get_object('t/data/eherkenning-assertion.xml');
  ok($response->has_assertions, "We have an assertion");
  ok($response->success, "It was successful");
  is($response->assertions->size, 3, "Got the correct amount or assertions");

  my $assertion = $response->to_assertion( insecure_trust_embedded_cert  => 1 );
  isa_ok($assertion, "Net::SAML2::Protocol::Assertion");
}


{
  throws_ok(sub{get_object('t/data/response-no-assertion.xml', 'INCORRECT_DESTINATION');},
      qr/Response Destination \(\[our SAML callback url\]\) does not match expected value \(INCORRECT_DESTINATION\)/, "Incorrect Destination fails as expected");
  my $response = get_object('t/data/response-no-assertion.xml', '[our SAML callback url]');
  ok(!$response->has_assertions, "We don't have an assertion");
  ok(!$response->success, "Unsuccessful response");
  is($response->status, STATUS_RESPONDER(), "... because its a status:Responder");
}

# require_signed_response handling (B2/B3)
{
  # Construct directly (not via get_object, which passes the argument
  # explicitly) and OMIT require_signed_response so the default is what is
  # exercised here.  insecure mode keeps the KeyName cacert gate out of it.
  my $response = Net::SAML2::Object::Response->new_from_xml(
      xml                          => path('t/data/eherkenning-assertion.xml')->slurp,
      insecure_trust_embedded_cert => 1,
  );
  isa_ok($response, 'Net::SAML2::Object::Response',
      'omitting require_signed_response constructs a Response');
  is($response->require_signed_response, 0,
      'require_signed_response attribute defaults to 0 when omitted');

  # An Assertion-only-signed response (no Response-level Signature) is
  # accepted by default ...
  lives_ok(sub {
      Net::SAML2::Object::Response->new_from_xml(
          xml    => path('t/data/saml-adfs-plain.xml')->slurp,
          cacert => 't/net-saml2-cacert.pem',
      );
      },
      'default require_signed_response accepts an Assertion-only-signed response');

  # ... but require_signed_response => 1 enforces a single Response-level
  # Signature and rejects an Assertion-only-signed response.
  throws_ok(sub {
      Net::SAML2::Object::Response->new_from_xml(
          xml                     => path('t/data/saml-adfs-plain.xml')->slurp,
          cacert                  => 't/net-saml2-cacert.pem',
          require_signed_response => 1,
      );
      },
      qr/include exactly one Signature/,
      'require_signed_response => 1 rejects an Assertion-only-signed response');

  # require_signed_response => 1 accepts a Response that carries exactly one
  # Response-level Signature.
  my $signed = Net::SAML2::Object::Response->new_from_xml(
      xml                     => path('t/data/eherkenning-assertion.xml')->slurp,
      cacert                  => 't/net-saml2-cacert.pem',
      require_signed_response => 1,
  );
  isa_ok($signed, 'Net::SAML2::Object::Response',
      'require_signed_response => 1 accepts a Response-level-signed response');
  is($signed->require_signed_response, 1,
      'require_signed_response => 1 is reflected on the object');
}

# require_signed_response is exempt for ArtifactResponse (B5): an
# ArtifactResponse is retrieved over an authenticated TLS back-channel, so it
# is not subject to the front-channel Response signature requirement even when
# require_signed_response => 1.  This uses an UNSIGNED ArtifactResponse so the
# test actually exercises the exemption (the real fixtures are wrapper-signed
# and would pass regardless).
{
  my $unsigned_artifact = <<'ARTIFACT';
<samlp:ArtifactResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="ID_unsigned_artifact" Version="2.0" IssueInstant="2023-01-29T16:21:09.254Z" InResponseTo="NETSAML2_req">
  <saml:Issuer>https://idp.example.com</saml:Issuer>
  <samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>
  <samlp:Response ID="ID_inner" Version="2.0" IssueInstant="2023-01-29T16:21:09.253Z">
    <saml:Issuer>https://idp.example.com</saml:Issuer>
    <samlp:Status><samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></samlp:Status>
  </samlp:Response>
</samlp:ArtifactResponse>
ARTIFACT

  my $artifact;
  lives_ok(
    sub {
           $artifact = Net::SAML2::Object::Response->new_from_xml(
             xml                     => $unsigned_artifact,
             cacert                  => 't/net-saml2-cacert.pem',
             require_signed_response => 1,
           );
    }, 'require_signed_response => 1 accepts an unsigned ArtifactResponse (back-channel exemption)'
  );
  isa_ok($artifact, 'Net::SAML2::Object::Response');
}
done_testing;
