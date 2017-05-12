use strict;
use Encode;
use Test::More 0.87; # done_testing
use Test::LWP::MockSocket::http;
use HTTP::Body;
use SMS::Send;

my %params = (_login => "testlogin", _password => "t3s+pass");

my $test_sender = SMS::Send->new("UK::AA",
  _endpoint => "http://t/sms.cgi", %params);

{
  $LWP_Response = resp("ERR: Invalid.", my $request);

  my $response = $test_sender->send_sms(
    to => "+1234567",
    text => "test message");

  is_deeply(query($request), {
      username => $params{_login},
      password => $params{_password},
      da => "+1234567",
      ud => "test message"
  });

  ok !$response;
  ok $response =~ /ERR: Invalid/;
  ok $response->status_line eq 'ERR: Invalid.';
}

{
  # Yes, A&A do \n and \r\n mixture too
  $LWP_Response = resp("SMS message to 1234\nOK: Queued\r\n", my $request);

  my $response = $test_sender->send_sms(
    to => "+1234567",
    text => "test");

  is_deeply(query($request), {
      username => $params{_login},
      password => $params{_password},
      da => "+1234567",
      ud => "test"
  });

  ok $response;
  ok $response =~ /OK: Queued/;
  ok $response->status_line eq 'OK: Queued';
}

{
  $LWP_Response = resp("SMS message to 1234\nOK: Queued\r\n", my $request);

  my $response = $test_sender->send_sms(
    to => "+1234567",
    text => "Here is some unicode: \x{1f30c}");

  is_deeply(query($request), {
      username => $params{_login},
      password => $params{_password},
      da => "+1234567",
      ud => encode_utf8("Here is some unicode: \x{1f30c}"),
  });

  ok $response;
  ok $response =~ /OK: Queued/;
  ok $response->status_line eq 'OK: Queued';
}

done_testing;

# Testing specific functions

# Set up a callback for use with Test::LWP::MockSocket::http
sub resp {
  my $data = shift;
  my $request = \$_[0];

  sub {
    $$request = $_[1] if $request;
    "HTTP/1.0 " . HTTP::Response->new(200, "OK",
      ['Content-type' => 'text/plain'],
      $data)->as_string
  }
}

# Grab the params out of a request's content
sub query {
  my($request) = @_;
  my $body = HTTP::Body->new($request->content_type, length $request->content);
  $body->add($request->content);
  return $body->param;
}
