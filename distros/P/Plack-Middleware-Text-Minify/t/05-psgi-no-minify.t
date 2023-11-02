#!perl

use utf8;

use v5.14;
use warnings;

use Test2::V0;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::MIME;
use Plack::Test;

my $Orig;

my $handler = builder {

    enable "Head";
    enable "Text::Minify";
    enable "ContentLength";


    sub {
        my $env    = shift;

        $env->{'psgix.no-minify'} = 1;

        my $path   = $env->{PATH_INFO};
        my $type   = Plack::MIME->mime_type($path);

        my $body = <<EOB;
<html>
  <head>
    <title>Test</title>
  </head>
  <body>
    <h1>Test</h1>
    <p>Here is some text.</p>
</html>
EOB

        $Orig = length($body);

        return [
            200,
            [
             'Content-Type' => $type || 'text/plain; charset=utf8',
             'Content-Length' => $Orig,
            ],
            [ $body ]
        ];
    };

};

test_psgi
    app => $handler,
    client => sub {
        my ($cb) = @_;

        subtest 'simple' => sub {

            my $req = GET '/';
            my $res = $cb->($req);

            like $res->content, qr/\n[ ]/, "has leading spaces";
            is $res->header('Content-Length'), $Orig, "content-length updated";

        };

};

done_testing;
