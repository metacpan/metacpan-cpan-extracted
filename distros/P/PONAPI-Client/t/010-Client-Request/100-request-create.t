#!perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

use JSON::MaybeXS qw( decode_json );

BEGIN {
    use_ok('PONAPI::Client::Request::Create');
}

my %TEST_DATA = (
    type => 'articles',
    data => {
        body    => "The 4nd shortest article. Ever.",
        created => "2015-08-22T14:56:29.000Z",
        status  => "pending approval",
        title   => "A forth title",
        updated => "2015-08-22T14:56:28.000Z",
    },
);

subtest '... testing object' => sub {

    my $req = PONAPI::Client::Request::Create->new( %TEST_DATA );

    isa_ok( $req, 'PONAPI::Client::Request::Create');
    does_ok($req, 'PONAPI::Client::Request');
    does_ok($req, 'PONAPI::Client::Request::Role::IsPOST');
    does_ok($req, 'PONAPI::Client::Request::Role::HasType');
    does_ok($req, 'PONAPI::Client::Request::Role::HasData');

    can_ok( $req, 'method' );
    can_ok( $req, 'path' );
    can_ok( $req, 'request_params' );

};

subtest '... testing request parameters' => sub {

    my $req = PONAPI::Client::Request::Create->new( %TEST_DATA );

    my $EXPECTED = +{
        method       => 'POST',
        path         => '/articles',
        body         => { data => $TEST_DATA{data} },
    };

    my $GOT = +{ $req->request_params };
    $GOT->{body} = decode_json($GOT->{body});

    is_deeply( $GOT, $EXPECTED, 'checked request parametes' );

};

done_testing;
