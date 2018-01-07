#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Status qw/ :constants :is /;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $handler = builder {
    enable "TimeOverHTTP";
    sub { };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'successful' => sub {
        my $time = time;

        my $req = HEAD "/.well-known/time";
        my $res = $cb->($req);

        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_NO_CONTENT, "no content";

        ok $res->header('X-HTTPSTIME') >= $time, 'X-HTTPSTIME';
    };

    subtest 'rejected' => sub {
        my $time = time;

        my $req = GET "/.well-known/time";
        my $res = $cb->($req);

        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_METHOD_NOT_ALLOWED, "bad method";
    };

  };

done_testing;
