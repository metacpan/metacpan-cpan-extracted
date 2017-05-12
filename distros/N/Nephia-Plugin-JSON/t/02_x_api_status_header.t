use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Nephia::Core;
use utf8;
use Encode;
use JSON;

subtest normal => sub {
    my $v = Nephia::Core->new(
        plugins => ['JSON' => {enable_api_status_header => 1} ],
        app => sub { json_res({foo => 'ばー'}) },
    );
    
    test_psgi $v->run, sub {
        my $cb     = shift;
        my $res    = $cb->(GET '/');
        is $res->header('X-API-Status'), 200;
        is_deeply(decode_json($res->content), +{status => 200, foo => 'ばー'}, 'output with JSON');
    };
};

done_testing;
