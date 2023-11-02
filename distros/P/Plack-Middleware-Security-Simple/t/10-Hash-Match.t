#!perl

use strict;
use warnings;

use Test2::V0;

use Hash::Match;
use HTTP::Status qw/ :constants :is /;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $rules = Hash::Match->new(
    rules => [
        PATH_INFO => qr{\.(php|asp)$},
        -and      => {
            PATH_INFO      => qr{^/cgi-bin/},
            REQUEST_METHOD => "POST",
        }
    ]
);

my $handler = builder {
    enable "Security::Simple",
        rules => $rules;

    sub { return [ HTTP_OK, [], ['Ok'] ] };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'not blocked' => sub {
        my $req = GET "/some/thing.html";
        my $res = $cb->($req);

        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";

    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing.php";
        my $res = $cb->($req);

        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";

    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing.php?stuff=1";
        my $res = $cb->($req);

        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";

    };

    subtest 'not blocked' => sub {
        my $req = GET "/cgi-bin/thing.html";
        my $res = $cb->($req);

        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";

    };


    subtest 'blocked' => sub {
        my $req = POST "/cgi-bin/thing?stuff=1";
        my $res = $cb->($req);

        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";

    };

 };

done_testing;
