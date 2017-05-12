use utf8;
use strict;
use warnings;
use t::Util qw(minified_js minified_css);
use Test::More;
use Test::Name::FromLine;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable 'Assets::RailsLike',
        root   => './t',
        minify => 1;
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'javascript' => sub {
            my $res = $cb->( GET '/assets/application.js' );
            is $res->code,    200;
            is $res->content, minified_js;
        };
        subtest 'css' => sub {
            my $res = $cb->( GET '/assets/application.css' );
            is $res->code,    200;
            is $res->content, minified_css;
        };
    }
);

done_testing;
