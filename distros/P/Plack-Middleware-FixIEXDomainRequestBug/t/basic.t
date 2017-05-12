use Test::Most;
use Plack::Middleware::FixIEXDomainRequestBug;
use HTTP::Message::PSGI;
use HTTP::Request;
use HTTP::Response;

ok my $app = Plack::Middleware::FixIEXDomainRequestBug->wrap(
  sub { +[200, ['Content-Type' => 'text/plain'], [pop->{CONTENT_TYPE}]] },
  force_content_type => 'application/json');

## This first set of tests demonstrates that having the middleware
## doesn't always munge up the request

ok my $good_request = HTTP::Request->new(POST => '/',
  ['Content-Type' => 'text/plain'], "xxxxx" )->to_psgi;

my $good_response = HTTP::Response->from_psgi($app->($good_request));

is $good_response->content, 'text/plain';

## However now lets make a 'bad' request, that meets the criteria

ok my $bad_request = HTTP::Request->new(POST => '/',
  ['User-Agent' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0;  en-US)'], "xxxxx" )->to_psgi;

ok my $bad_response = HTTP::Response->from_psgi($app->($bad_request));

is $bad_response->content, 'application/json';

done_testing;
