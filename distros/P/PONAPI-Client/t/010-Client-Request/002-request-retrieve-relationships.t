#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Client::Request::RetrieveRelationships');
}

my %TEST_DATA = (
    type     => 'articles',
    id       => 2,
    rel_type => 'comments',
    page     => { size => 50 },
    filter   => { status => [ "ok" ] },
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::RetrieveRelationships->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::RetrieveRelationships');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsGET');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasId');
    does_ok($req, 'PONAPI::Client::Request::Role::HasRelationshipType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasFilter');
    does_ok($req, 'PONAPI::Client::Request::Role::HasPage');

    can_ok( $req, 'method' );
    can_ok( $req, 'path' );
    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::RetrieveRelationships->new( %TEST_DATA );

    my $EXPECTED = +{
        method       => 'GET',
        path         => '/articles/2/relationships/comments',
        query_string => 'filter%5Bstatus%5D=ok&page%5Bsize%5D=50',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
