use strict;
use DateTime;
use LWP::UserAgent;
use Test::More;
# use Net::Amazon::AlexaValidator;

# This test will fail. The signature is all wrong. However, I don't have access to Amazon's
# private key :) so I can't generate a correct one.
  # my $request_body = {
  #     session => {
  #       sessionId => "SessionId.990eb6d0-939a-4698-a965-546f9747fd64",
  #       application => {
  #         applicationId => "my_application_id_from_amazon_dev_site"
  #       },
  #       attributes => {},
  #       user => {
  #         userId => "amzn1.ask.account.fakeUserId"
  #       },
  #     },
  #     request => {
  #       type => "IntentRequest",
  #       requestId => "EdwRequestId.26cad6f6-5abf-4a13-93ae-130c2ab250f7",
  #       locale => "en-US",
  #       timestamp => DateTime->now()->iso8601().'Z',
  #       intent => {
  #       }
  #     },
  #     version => "1.0"
  #   };
  # my $request = HTTP::Request->new();
  # $request->content_type('application/json');
  # $request->content(JSON::encode_json($request_body));
  # $request->header(signaturecertchainurl => 'https://s3.amazonaws.com/echo.api/echo-api-cert-3.pem');
  # $request->header(signature => 'fake_signature');

  # my $alexa_validator = Net::Amazon::AlexaValidator->new({
  #   application_id => 'my_application_id_from_amazon_dev_site',
  #   echo_domain    => 'DNS:echo-api.amazon.com',
  #   cert_dir       => '/tmp/',
  #   test_mode      => 1
  #   });

  # my $ret = $alexa_validator->validate_request($request);

  # ok $ret->{success}, 'Validated Amazon request';

done_testing;
