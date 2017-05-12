use utf8;
use strict;
use warnings;
use t::Util qw(minified_js);
use Test::More;
use Test::Name::FromLine;
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

        subtest '404 - Not Found' => sub {
            my $res = $cb->( GET '/assets/not-found.js' );
            is $res->code,    404;
            is $res->content, 'Not Found';
        };

        local $SIG{__WARN__} = sub {};
        chmod 0000, './t/assets/not-read.js';
        subtest '500 - Internal Server Error' => sub {
            my $res = $cb->( GET '/assets/not-read.js' );
            is $res->code,    500;
            is $res->content, 'Internal Server Error';
        };
        chmod 0664, './t/assets/not-read.js';
    }
);

done_testing;
