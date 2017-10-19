use strict;
use Test::More;
use Plack::App::URLMux;
use Plack::Test;
use HTTP::Request::Common;

my $app_not_found = sub {
    my $env = shift;
    return [ 404, [ 'Content-Type' => 'text/plain' ], [ "'$env->{PATH_INFO}' not found." ] ];
};


my $mux = Plack::App::URLMux->new;
$mux->map('' => $app_not_found);

test_psgi app => $mux, client => sub {
    my $cb = shift;

    my $res;

    $res = $cb->(GET "http://localhost/");
    is $res->content, "'/' not found.";

};

done_testing;
