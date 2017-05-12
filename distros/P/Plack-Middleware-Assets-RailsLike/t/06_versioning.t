use utf8;
use strict;
use warnings;
use t::Util qw(minified_js);
use Test::More;
use Test::Name::FromLine;
use Test::Time;
use Plack::Test;
use Plack::Builder;
use HTTP::Date;
use HTTP::Request::Common;

my $app = builder {
    enable 'Assets::RailsLike', root => './t';
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;

        subtest 'pre-compiled' => sub {
            my $res = $cb->( GET '/assets/application-precompiled.js' );
            is $res->code,    200;
            is $res->content, 'var precompiled = 1;';
        };

        subtest 'compile on the fly' => sub {
            my $res = $cb->( GET '/assets/application-123456789.js' );
            is $res->code,    200;
            is $res->content, minified_js;
        };

    }
);

done_testing;
