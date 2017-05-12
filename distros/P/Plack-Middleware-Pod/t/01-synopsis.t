#!perl -T
use strict;
use warnings;

use Test::More tests => 2;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Pod;

my $app = sub { return [ 404, [], [ "Nothing to see here"] ] };

$app = Plack::Middleware::Pod->wrap($app,
      path => qr{^/pod/},
      root => './lib/',
      pod_view => 'Pod::POM::View::HTML', # the default
);


# Simple OO interface
my $test = Plack::Test->create($app);

my $res = $test->request(GET "/pod/Plack/Middleware/Pod.pm");
like $res->content, qr/\bPlack::Middleware::Pod\b/, "We render pod";

$res = $test->request(GET "/pod/../Makefile.PL");
is $res->code, 404, "Escaping outside of the directory doesn't work"
    or diag $res->content;

