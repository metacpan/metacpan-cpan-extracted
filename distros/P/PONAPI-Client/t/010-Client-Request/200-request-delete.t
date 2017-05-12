#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

use JSON::MaybeXS qw( encode_json );

BEGIN {
    use_ok('PONAPI::Client::Request::Delete');
}

my %TEST_DATA = (
    type => 'articles',
    id   => 2,
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::Delete->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::Delete');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsDELETE');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasId');

    can_ok( $req, 'method' );
    can_ok( $req, 'path' );
    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::Delete->new( %TEST_DATA );

    my $EXPECTED = +{
        method       => 'DELETE',
        path         => '/articles/2',
    };

    my $GOT = +{ $req->request_params };

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
