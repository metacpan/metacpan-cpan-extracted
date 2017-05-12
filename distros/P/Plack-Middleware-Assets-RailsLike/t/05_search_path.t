use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = builder {
    enable 'Assets::RailsLike',
        root        => './t',
        search_path => [qw(t/ya-assets t/assets)],
        minify      => 0;
    sub { [ 200, [ 'Content-Type', 'text/html' ], ['OK'] ] };
};

test_psgi(
    app    => $app,
    client => sub {
        my $cb  = shift;
        my $res = $cb->( GET '/assets/search_path.js' );
        is $res->code,    200;
        is $res->content, "var foo = 1;\n\"load from ya-assets\";";
    }
);

done_testing;
