use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use Plack::Middleware::JSONParser;
use HTTP::Request::Common;

my $parsed_request;
my $error;
my $app = sub {
    my $env = shift;
    [ 200, 
      ['Content-Type' => 'text/plain'], 
      [
        $error = $env->{'plack.middleware.jsonparser.error'},
        $parsed_request = Plack::Request->new($env),
      ]
    ];
};
$app = Plack::Middleware::JSONParser->wrap($app);

test_psgi $app, sub {
  my $cb = shift;
  my $req = HTTP::Request->new(POST => "/");
  # parse json body
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('{ "name" : "yosuke", "age" : 31}');
  $cb->($req);
  is $parsed_request->param('name'), "yosuke";
  is $parsed_request->param('age'), 31;

  # with query string
  $req = HTTP::Request->new(POST => "/?test1=123&test2=abc");
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('{ "name" : "yosuke", "age" : 31}');
  $cb->($req);
  is $parsed_request->param('name'), "yosuke";
  is $parsed_request->param('age'), 31;
  is $parsed_request->param('test1'), 123;
  is $parsed_request->param('test2'), "abc";

  # with empty body
  $req = HTTP::Request->new(POST => "/?test3=123&test4=abc");
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('');
  $cb->($req);
  is $parsed_request->param('test3'), 123;
  is $parsed_request->param('test4'), "abc";

  # with array only json
  $req = HTTP::Request->new(POST => "/?test3=123&test4=abc");
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('[123]');
  $cb->($req);
  is $parsed_request->param('test3'), 123;
  is $parsed_request->param('test4'), "abc";

  # invalid json
  $req = HTTP::Request->new(POST => "/?test3=123&test4=abc");
  $req->header('Content_Type' => 'application/json; charset=utf-8');
  $req->content('abc=123');
  $cb->($req);
  is $parsed_request->param('test3'), 123;
  is $parsed_request->param('test4'), "abc";
  like $error, qr/malformed JSON/;
};

done_testing;
