#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Client::Request::RetrieveAll');
}

my %TEST_DATA = (
    type    => 'articles',
    fields  => { articles => [qw< title body >] },
    filter  => { id => [ 2, 3 ] },
    include => [qw< comments author >],
    sort    => [ '-name' ],
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::RetrieveAll->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::RetrieveAll');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsGET');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFields');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFilter');
    does_ok($req, 'PONAPI::Client::Request::Role::HasInclude');
    does_ok($req, 'PONAPI::Client::Request::Role::HasPage');
    does_ok($req, 'PONAPI::Client::Request::Role::HasSort');

    can_ok( $req, 'method' );
    can_ok( $req, 'path' );
    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::RetrieveAll->new( %TEST_DATA );

    my $expected_query_string =
        'fields%5Barticles%5D=title%2Cbody&filter%5Bid%5D=2%2C3&include=comments%2Cauthor&sort=-name';

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/articles',
        query_string => $expected_query_string,
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
