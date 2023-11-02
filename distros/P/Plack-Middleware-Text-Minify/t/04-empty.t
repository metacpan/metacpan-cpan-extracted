#!perl

use utf8;

use v5.14;
use warnings;

use Test2::V0;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::MIME;
use Plack::Test;

my $handler = builder {

    enable "Head";
    enable "Text::Minify";
    enable "ContentLength";


    sub {
        my $env    = shift;
        my $path   = $env->{PATH_INFO};
        my $type   = Plack::MIME->mime_type($path);

        my ($code) = $path =~ qr{^/([1-5][0-9][0-9])};

        return [
            $code || 200,
            [
             'Content-Type' => $type || 'text/plain; charset=utf8',
             'Content-Length' => 0,
            ],
            [ '' ]
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

            is $res->content, "", "blank";

        };

        subtest 'HTTP 204' => sub {

            my $req = GET '/204';
            my $res = $cb->($req);

            is $res->code, 204, 'expected HTTP response';

        };

        subtest 'HTTP 304' => sub {

            my $req = GET '/304';
            my $res = $cb->($req);

            is $res->code, 304, 'expected HTTP response';

        };

        subtest 'head' => sub {

            my $req = HEAD '/';
            my $res = $cb->($req);

            is $res->content, "", "blank";

        };

};

done_testing;
