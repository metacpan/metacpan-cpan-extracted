use utf8;
use strict;
use warnings;
use t::Util qw(compiled_js compiled_css);
use Test::More;
use Test::Name::FromLine;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

local $ENV{PLACK_ENV} = 'development';

my $app = builder {
    enable 'Assets::RailsLike',
        root    => './t',
        expires => 12345,
        minify  => 0;
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'javascript' => sub {
            my $res = $cb->( GET '/assets/application.js' );
            is $res->code,    200;
            is $res->content, compiled_js;
            is $res->header('Cache-Control'), 'no-store';
            ok !$res->header('Etag');
        };

        subtest 'css' => sub {
            my $res = $cb->( GET '/assets/application.css' );
            is $res->code,    200;
            is $res->content, compiled_css;
            is $res->header('Cache-Control'), 'no-store';
            ok !$res->header('Etag');
        };

        subtest 'with versioning' => sub {
            my $res = $cb->( GET '/assets/application-123456789.js' );
            is $res->code,    200;
            is $res->content, compiled_js;
            is $res->header('Cache-Control'), 'no-store';
            ok !$res->header('Etag');
        };
    }
);

done_testing;
