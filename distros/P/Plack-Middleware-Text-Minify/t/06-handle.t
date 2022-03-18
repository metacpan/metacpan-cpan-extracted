#!perl

use utf8;

use strict;
use warnings;

use Test::Most;

use File::Temp qw/ tempfile /;
use HTTP::Request::Common;
use IO::File;
use Plack::Builder;
use Plack::MIME;
use Plack::Test;

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

my $Orig = length($body);

my ($fh, $fname) = tempfile();

say {$fh} $body;

close $fh;

my $handler = builder {

    enable "Head";
    enable "Text::Minify";
    enable "ContentLength";


    sub {
        my $env    = shift;
        my $path   = $env->{PATH_INFO};
        my $type   = Plack::MIME->mime_type($path);
        my $body   = IO::File->new($fname, "r");

        return [
            200,
            [
             'Content-Type' => $type || 'text/plain; charset=utf8',
             'Content-Length' => $Orig,
            ],
            $body
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

            unlike $res->content, qr/\n[ ]/, "no leading spaces";
            isnt $res->header('Content-Length'), $Orig, "content-length updated";
            is $res->header('Content-Length'), 97, "content-length lower";

        };

        subtest 'not text' => sub {

            my $req = GET '/test.jpg';
            my $res = $cb->($req);

            like $res->content, qr/\n[ ]/, "has leading spaces";

            is $res->header('Content-Length'), $Orig, "content-length unchanged";

        };

        subtest 'head' => sub {

            my $req = HEAD '/';
            my $res = $cb->($req);

            unlike $res->content, qr/\n[ ]/, "no leading spaces";
        };

};

done_testing;
