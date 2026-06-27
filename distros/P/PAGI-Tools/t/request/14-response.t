use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(refaddr);
use PAGI::Request;
use PAGI::Response;

subtest 'request vends a response bound to its scope' => sub {
    my $scope = { type => 'http', method => 'GET', headers => [], path => '/' };
    my $req = PAGI::Request->new($scope, sub { });

    my $res = $req->response;
    isa_ok($res, ['PAGI::Response'], 'response() returns a PAGI::Response');
    is($res->scope, $scope, 'response is bound to the request scope');
    isnt(refaddr($req->response), refaddr($res), 'each call vends a fresh response');
};

done_testing;
