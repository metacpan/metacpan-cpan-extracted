use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::unAPI;
use Plack::Request;

my $app = unAPI(
    foo => [ sub { "x" } => 'text/plain' ],
    bar => [ sub { die("x") } => 'text/plain' ],
);

test_psgi $app, sub {
    my ($cb, $res) = @_;

    $res = $cb->(GET "/?id=abc&format=foo");
    is( $res->code, 500, 'Internal error' );
    is( $res->content, 'No PSGI response for format=foo and id=abc', 'no PSGI' );

    $res = $cb->(GET "/?id=abc&format=bar");
    is( $res->code, 500, 'Internal error' );
    is( $res->content, "Internal crash with format=bar and id=abc: x at t/500.t line 11.\n", 'crash' );
};

done_testing;
