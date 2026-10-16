#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;
use Test::MockModule qw{strict};
use Plack::Test;
use HTTP::Request::Common qw{GET PUT};
use HTTP::Request         ();
use Cpanel::JSON::XS      ();

use PowerDNS::API::ACL::Proxy;

{

    package Fake::Store;
    sub new              { my ( $class, %grants_of ) = @_; return bless {%grants_of}, $class }
    sub grants_for_token { my ( $self,  $token )     = @_; return @{ $self->{$token} // [] } }
}

my $JSON = Cpanel::JSON::XS->new->utf8->canonical;
my $ZONE = 'lab.test.test.';
my $PATH = "/api/v1/servers/localhost/zones/$ZONE";

my $store = Fake::Store->new( web => [ { zone => $ZONE, name => "web.$ZONE", types => ['A'], access => 'write' } ] );

# What PowerDNS was asked, and what it answers.
my @asked;
my %answer = ( status => 200, success => 1, headers => { 'content-type' => 'application/json' }, content => q{} );
my $http   = Test::MockModule->new('HTTP::Tiny');
$http->redefine(
    request => sub {
        my ( undef, $method, $url, $args ) = @_;
        push( @asked, { method => $method, url => $url, %{ $args // {} } } );
        return {%answer};
    }
);

sub app_for {
    my (%opts) = @_;
    return Plack::Test->create( PowerDNS::API::ACL::Proxy->new( store => $store, api_key => 'the-real-key', upstream => '/bogus/api.sock', %opts )->to_app );
}

sub patch {
    my ( $token, $body ) = @_;
    my $req = HTTP::Request->new( PATCH => $PATH, [ 'X-API-Key' => $token, 'Content-Type' => 'application/json' ], $body );
    return app_for()->request($req);
}

subtest 'an allowed PATCH reaches PowerDNS with the real key' => sub {
    @asked  = ();
    %answer = ( %answer, status => 204, content => q{} );
    my $body = $JSON->encode( { rrsets => [ { name => "web.$ZONE", type => 'A', changetype => 'REPLACE', records => [ { content => '192.0.2.1', disabled => Cpanel::JSON::XS::false } ] } ] } );
    my $res  = patch( 'web', $body );

    is( $res->code,                      204,                          'the client gets the answer of PowerDNS' );
    is( scalar @asked,                   1,                            'PowerDNS was asked once' ) or return;
    is( $asked[0]{method},               'PATCH',                      'with the method of the client' );
    is( $asked[0]{url},                  "http:/bogus/api.sock/$PATH", 'over the socket, at the path of the client' );
    is( $asked[0]{headers}{'X-API-Key'}, 'the-real-key',               'with the real key, not the token' );
    is( $asked[0]{content},              $body,                        'and the body as the client sent it' );
};

subtest 'a refused request never reaches PowerDNS' => sub {
    @asked = ();
    my $res = patch( 'web', $JSON->encode( { rrsets => [ { name => "db.$ZONE", type => 'A', changetype => 'REPLACE' } ] } ) );
    is( $res->code, 403, 'refused' );
    like( $JSON->decode( $res->content )->{error}, qr/db[.]lab/, 'with a body as PowerDNS writes an error' );

    my $unknown = app_for()->request( GET $PATH, 'X-API-Key' => 'nobody' );
    is( $unknown->code, 401, 'an unknown key is unauthenticated' );

    my $nokey = app_for()->request( GET $PATH );
    is( $nokey->code, 401, 'and so is no key at all' );

    my $garbage = patch( 'web', '{not json' );
    is( $garbage->code, 400, 'a body that is not JSON is refused before it is judged' );

    is( scalar @asked, 0, 'and none of them was passed on' );
};

subtest 'a GET of the zone comes back with only what the key may read' => sub {
    @asked  = ();
    %answer = ( %answer, status => 200, content => $JSON->encode( { name => $ZONE, rrsets => [ { name => $ZONE, type => 'SOA' }, { name => "web.$ZONE", type => 'A' }, { name => "db.$ZONE", type => 'A' } ] } ) );

    my $res = app_for()->request( GET "$PATH?rrsets=true", 'X-API-Key' => 'web' );
    is( $res->code,                                                           200,                                      'allowed' );
    is( [ map { $_->{name} } @{ $JSON->decode( $res->content )->{rrsets} } ], ["web.$ZONE"],                            'the other records of the zone are not in the answer' );
    is( $asked[0]{url},                                                       "http:/bogus/api.sock/$PATH?rrsets=true", 'and the query string went along' );
};

subtest 'an upstream that is a URL' => sub {
    @asked = ();
    app_for( upstream => 'http://127.0.0.1:8081/' )->request( PUT "$PATH/notify", 'X-API-Key' => 'web' );
    is( $asked[0]{url}, "http://127.0.0.1:8081$PATH/notify", 'is used as it is, without a doubled slash' );
};

subtest 'PowerDNS that does not answer is a bad gateway, not a refusal' => sub {
    %answer = ( status => 599, success => 0, headers => {}, content => 'Could not connect' );
    my $res = app_for()->request( PUT "$PATH/notify", 'X-API-Key' => 'web' );
    is( $res->code, 502, 'a 502' );
    like( $JSON->decode( $res->content )->{error}, qr/did[ ]not[ ]answer:[ ]Could[ ]not[ ]connect/, 'saying why' );
};

subtest 'new names what it is missing' => sub {
    like( dies { PowerDNS::API::ACL::Proxy->new( store    => $store, upstream => '/x' ) }, qr/needs[ ]api_key/,  'the key' );
    like( dies { PowerDNS::API::ACL::Proxy->new( store    => $store, api_key  => 'k' ) },  qr/needs[ ]upstream/, 'the upstream' );
    like( dies { PowerDNS::API::ACL::Proxy->new( upstream => '/x',   api_key  => 'k' ) },  qr/needs[ ]db/,       'and the store' );
};

done_testing;
