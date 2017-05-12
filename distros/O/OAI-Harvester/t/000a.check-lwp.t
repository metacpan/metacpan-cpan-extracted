use Test::More tests => 3;

use strict;
use warnings;

use LWP::UserAgent;

st( 'http://www.google.com/', 1);
st( 'http://www.google.com:54321/', 0);
st( 'http://www.google.com/', 1);

sub st {
  my ($url, $expected) = @_;

  subtest "GET $url" => sub {
      plan tests => 4;

      my ($req, $ua, $res); 
      isa_ok($ua = LWP::UserAgent->new, 'LWP::UserAgent');
      isa_ok($req = HTTP::Request->new(GET => $url), 'HTTP::Request');
# send request
      isa_ok($res = $ua->request($req), 'HTTP::Response');
      if ( $expected ) {
          like($res->status_line, qr/^2/, "request to $url should be successful")}
      else {
          like($res->status_line, qr/^[45]/, "request to $url should return an error")}
    };
}

