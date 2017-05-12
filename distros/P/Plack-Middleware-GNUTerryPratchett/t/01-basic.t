use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $content = [qw/hello world/];

my $handler = builder {
    enable "Plack::Middleware::GNUTerryPratchett";

    sub { [ '200', [ 'Content-Type' => 'text/html' ], $content ] };
};

test_psgi
  app => $handler,
  client => sub {
    my $cb = shift;
    {
      my $req = GET "http://localhost/";
      my $res = $cb->($req);
      ok $res->header('X-Clacks-Overhead'), 'X-Clacks-Overhead should be present';
      is $res->header('X-Clacks-Overhead'), 'GNU Terry Pratchett', 'should fill the header with the right value';
    }
  };

done_testing;
