use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use Data::Dumper;
use Plack::Middleware::JSONParser;
use HTTP::Request::Common;

my $parsed_request;
my $app = sub {
    my $env = shift;
    [200, ['Content-Type' => 'text/plain'], [
        $parsed_request = Plack::Request->new($env),
      ]
    ];
};
$app = Plack::Middleware::JSONParser->wrap($app, die_when_failed => 1);

test_psgi $app, sub {
  my $cb = shift;
  my $req = HTTP::Request->new(POST => "/");
  # parse json body
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('{ "name" : "yosuke", "age" : 31}');
  $cb->($req);
  is $parsed_request->param('name'), "yosuke";
  is $parsed_request->param('age'), 31;

  # invalid json
  $req = HTTP::Request->new(POST => "/?test3=123&test4=abc");
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('abc=123');
  my $res = $cb->($req);
  like $res->content, qr/malformed JSON/;
};

done_testing;

