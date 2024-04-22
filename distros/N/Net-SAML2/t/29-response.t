use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Object::Response;
use URN::OASIS::SAML2 qw(STATUS_RESPONDER STATUS_AUTH_FAILED);

sub get_object {
  my $xml = path(shift)->slurp;
  my $response = Net::SAML2::Object::Response->new_from_xml(xml => $xml);
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
  my $response = get_object('t/data/eherkenning-assertion.xml');
  ok($response->has_assertions, "We have an assertion");
  ok($response->success, "It was successful");
  is($response->assertions->size, 3, "Got the correct amount or assertions");

  my $assertion = $response->to_assertion();
  isa_ok($assertion, "Net::SAML2::Protocol::Assertion");
}


{
  my $response = get_object('t/data/response-no-assertion.xml');
  ok(!$response->has_assertions, "We don't have an assertion");
  ok(!$response->success, "Unsuccessful response");
  is($response->status, STATUS_RESPONDER(), "... because its a status:Responder");
}
done_testing;
