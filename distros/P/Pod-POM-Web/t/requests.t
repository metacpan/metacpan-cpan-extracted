#!perl

use Test::More tests => 11;
use HTTP::Request;
use HTTP::Response;
use Module::Metadata;

BEGIN {
	use_ok( 'Pod::POM::Web' );
}


diag( "Testing Pod::POM::Web $Pod::POM::Web::VERSION, Perl $], $^X" );

response_like("", qr/frameset/, "index 1");
response_like("/", qr/frameset/, "index 2");

response_like("/index", qr/frameset/, "index 3");

response_like("/Alien/GvaScript/lib/GvaScript.css", qr/AC_dropdown/, "lib");

SKIP: {
  my ($funcpod) = Pod::POM::Web->find_source("perlfunc")
    or skip "no perlfunc on this system", 3;

  response_like("/search?source=perlfunc&search=shift", qr/array/, "perlfunc");
  response_like("/toc/HTTP", qr/Request.*?Response/, "toc/HTTP");

  my ($varpod) = Pod::POM::Web->find_source("perlvar")
    or skip "no perlvar on this system", 1;

  response_like("/toc", qr/Modules/, "toc");
}


SKIP: {
  my ($faqpod) = Pod::POM::Web->find_source("perlfaq")
    or skip "no perlfaq on this system", 1;
  response_like("/search?source=perlfaq&search=array",  qr/array/, "perlfaq");
}


response_like("/source/HTTP/Request",  qr/HTTP::Request/, "source");

# regex for testing if the generated HTML contains the module title
# and version number ...  some versions of HTTP::Request don't
# have a version number
my $mm = Module::Metadata->new_from_module('HTTP::Request');
my $http_req_version = $mm && $mm->version;
my $regex = 'HTTP::Request</h1>\s*<small>';
$regex   .= '\(v.\s*' . $http_req_version if $http_req_version;

# now the actual test
response_like("/HTTP/Request",  qr/$regex/, "serve_pod");

sub response_like {
  my ($url, $like, $msg) = @_;
   my $response = get_response($url);
  like($response->content, $like, $msg);
}


sub get_response {
  my ($url) = @_;
  my $request  = HTTP::Request->new(GET => $url);
  my $response = HTTP::Response->new;
  Pod::POM::Web->handler($request, $response);
  return $response;
}


