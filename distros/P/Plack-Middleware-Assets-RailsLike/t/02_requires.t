use utf8;
use strict;
use warnings;
use t::Util qw(compiled_js compiled_css);
use Test::More;
use Test::Name::FromLine;
use Test::Time;
use Digest::SHA1 qw(sha1_hex);
use Plack::Test;
use Plack::Builder;
use HTTP::Date;
use HTTP::Request::Common;

# Freeze
my $now = time();
my $expires_in_secs = 3 * 24 * 60 * 60;

my $app = builder {
    enable 'Assets::RailsLike', root => './t', expires => '3day', minify => 0;
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'app' => sub {
            my $res = $cb->( GET '/' );
            is $res->code,    200;
            is $res->content, 'OK';
        };

        my $etag = sha1_hex(compiled_js);
        subtest 'javascript' => sub {
            my $res = $cb->( GET '/assets/application.js' );
            is $res->code,    200;
            is $res->content, compiled_js;
            is $res->header('Content-Type'), 'application/javascript';
            is $res->header('Cache-Control'), "max-age=$expires_in_secs";
            is $res->header('Expires'), time2str( $now + $expires_in_secs );
            is $res->header('Etag'), $etag;
        };

        subtest 'with etag' => sub {
            my $res = $cb->( GET '/assets/application.js', 'If-None-Match', $etag );
            is $res->code,    304;
            is $res->content, 'Not Modified';
        };

        subtest 'css' => sub {
            my $res = $cb->( GET '/assets/application.css' );
            is $res->code,    200;
            is $res->content, compiled_css;
        };
    }
);

done_testing;
