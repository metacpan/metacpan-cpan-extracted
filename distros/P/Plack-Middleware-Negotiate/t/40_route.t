use strict;
use warnings;
use v5.10;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Negotiate;

my $json_app = sub { [200,[],['{"x":"y"}']] };
my $html_app = sub { [200,[],['XY']] };

my $app = Plack::Middleware::Negotiate->new(
    formats => {
        json => { 
            type => 'application/json',
            app  => $json_app,
        },
        html => {
            type => 'text/html',
            app  => $html_app,
        }
    }
);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/', Accept => 'application/json');
    is $res->content, '{"x":"y"}', 'routed to json_app';

    $res = $cb->(GET '/', Accept => 'text/html');
    is $res->content, 'XY', 'routed to html_app';

    $res = $cb->(GET '/', Accept => 'foo/bar');
    is $res->code, '406', 'not acceptable';
};

done_testing;
