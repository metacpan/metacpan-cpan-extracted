#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;

use PowerDNS::API::ACL;

# A store that answers from a hash rather than from SQLite, so that these cases
# are the policy and nothing else.
{

    package Fake::Store;
    sub new              { my ( $class, %grants_of ) = @_; return bless {%grants_of}, $class }
    sub grants_for_token { my ( $self,  $token )     = @_; return @{ $self->{$token} // [] } }
}

my $ZONE = 'lab.test.test.';
my $PATH = "/api/v1/servers/localhost/zones/$ZONE";

my $acl = PowerDNS::API::ACL->new(
    store => Fake::Store->new(
        web    => [ { zone => $ZONE, name => "web.$ZONE",   types => [qw{A AAAA}], access => 'write' }, { zone => $ZONE, name => "_acme-challenge.web.$ZONE", types => ['TXT'], access => 'write' } ],
        reader => [ { zone => $ZONE, name => "*.$ZONE",     types => ['*'],        access => 'read' } ],
        apex   => [ { zone => $ZONE, name => "*.svc.$ZONE", types => ['*'],        access => 'write' } ],
        owner  => [ { zone => $ZONE, name => $ZONE,         types => ['*'],        access => 'manage' } ],
    ),
);

sub patch {
    my ( $token, @rrsets ) = @_;
    return $acl->authorize( token => $token, method => 'PATCH', path => $PATH, body => { rrsets => [ map { { name => $_->[0], type => $_->[1], changetype => 'REPLACE' } } @rrsets ] } );
}

subtest 'canonical_name' => sub {
    is( PowerDNS::API::ACL->canonical_name('Web.Lab.Test.Test'), "web.$ZONE", 'lower case, with the trailing dot added' );
    is( PowerDNS::API::ACL->canonical_name("web.$ZONE.."),       "web.$ZONE", 'and one dot where there were several' );
    is( PowerDNS::API::ACL->canonical_name(undef),               q{.},        'nothing is the root' );
};

subtest 'covers' => sub {
    my $one  = { name => "web.$ZONE",   types => ['A'] };
    my $tree = { name => "*.svc.$ZONE", types => ['*'] };

    ok( PowerDNS::API::ACL->covers( $one,  'WEB.lab.test.test', 'a' ),   'one name, in any case, and its type in any case' );
    ok( !PowerDNS::API::ACL->covers( $one, "web.$ZONE",         'TXT' ), 'but not another type' );
    ok( !PowerDNS::API::ACL->covers( $one, "x.web.$ZONE",       'A' ),   'nor a name below it' );

    ok( PowerDNS::API::ACL->covers( $tree,  "a.svc.$ZONE",   'CNAME' ), 'a pattern covers a name one label below it' );
    ok( PowerDNS::API::ACL->covers( $tree,  "a.b.svc.$ZONE", 'A' ),     'and one any depth below' );
    ok( !PowerDNS::API::ACL->covers( $tree, "svc.$ZONE",     'A' ),     'but not the name it is a pattern under' );
    ok( !PowerDNS::API::ACL->covers( $tree, "xsvc.$ZONE",    'A' ),     'nor a name that only ends with the same letters' );
};

subtest 'an unknown key is told so, and not what it could reach' => sub {
    my $v = $acl->authorize( token => 'nobody', method => 'GET', path => $PATH );
    is( [ @{$v}{qw{allow status}} ], [ 0, 401 ], 'refused as unauthenticated' );
};

subtest 'only the records of a zone are open' => sub {
    foreach my $path ( qw{/api/v1/servers /api/v1/servers/localhost/zones /api/v1/servers/localhost/config /api/v1/servers/localhost/search-data}, "$PATH/rectify", "$PATH/export" ) {
        my $v = $acl->authorize( token => 'web', method => 'GET', path => $path );
        is( [ @{$v}{qw{allow status}} ], [ 0, 403 ], "$path is refused" );
    }

    my $other = $acl->authorize( token => 'web', method => 'GET', path => '/api/v1/servers/localhost/zones/other.test.test.' );
    is( $other->{allow}, 0, 'and a zone the key has no grant in' );

    foreach my $method (qw{PUT POST DELETE}) {
        is( $acl->authorize( token => 'web', method => $method, path => $PATH )->{allow}, 0, "$method on the zone itself" );
    }
};

subtest 'a key reads its zone through a filter' => sub {
    my $v = $acl->authorize( token => 'web', method => 'GET', path => "/api/v1/servers/localhost/zones/LAB.test.test" );
    ok( $v->{allow}, 'a GET of a zone with a grant in it, however the zone is spelt' );
    is( scalar @{ $v->{filter} }, 2, 'carrying the grants of that zone for the filter' );

    my %zone = (
        name   => $ZONE,
        rrsets => [ map { { name => $_->[0], type => $_->[1] } } [ $ZONE, 'SOA' ], [ "web.$ZONE", 'A' ], [ "web.$ZONE", 'TXT' ], [ "db.$ZONE", 'A' ], [ "_acme-challenge.web.$ZONE", 'TXT' ] ],
    );
    PowerDNS::API::ACL->filter_zone( \%zone, $v->{filter} );
    is( [ map { "$_->{name} $_->{type}" } @{ $zone{rrsets} } ], [ "web.$ZONE A", "_acme-challenge.web.$ZONE TXT" ], 'the response keeps only the records the key may read' );
    is( $zone{name},                                            $ZONE,                                              'and the rest of the zone as it was' );
};

subtest 'a PATCH is allowed only when the key may write every rrset in it' => sub {
    ok( patch( 'web', [ "web.$ZONE", 'A' ], [ "web.$ZONE", 'AAAA' ] )->{allow}, 'its own name, in the types it was granted' );
    ok( patch( 'web',  [ "_acme-challenge.web.$ZONE", 'TXT' ] )->{allow},   'and the challenge record of its own name' );
    ok( patch( 'apex', [ "a.b.svc.$ZONE",             'CNAME' ] )->{allow}, 'and any name under a pattern' );

    my $mixed = patch( 'web', [ "web.$ZONE", 'A' ], [ "db.$ZONE", 'A' ] );
    is( [ @{$mixed}{qw{allow status}} ], [ 0, 403 ], 'one rrset it may not write refuses the whole PATCH' );
    like( $mixed->{reason}, qr/A[ ]records[ ]of[ ]db[.]lab/, 'naming that rrset' );

    is( patch( 'web',    [ "web.$ZONE", 'MX' ] )->{allow}, 0, 'a type it was not granted' );
    is( patch( 'reader', [ "web.$ZONE", 'A' ] )->{allow},  0, 'a key that may only read' );
    is( patch('web')->{allow}, 0, 'a PATCH with no rrsets' );
};

subtest 'notify needs write access to the zone' => sub {
    ok( $acl->authorize( token => 'web',    method => 'PUT', path => "$PATH/notify" )->{allow}, 'a key that may write' );
    is( $acl->authorize( token => 'reader', method => 'PUT', path => "$PATH/notify" )->{allow}, 0, 'not one that may only read' );
    is( $acl->authorize( token => 'web',    method => 'GET', path => "$PATH/notify" )->{allow}, 0, 'and only by PUT' );
};

subtest 'a manage grant creates and deletes its zone, and nothing else' => sub {
    my $zones = '/api/v1/servers/localhost/zones';

    ok( $acl->authorize( token => 'owner', method => 'POST', path => $zones, body => { name => 'Lab.test.test', kind => 'Native' } )->{allow}, 'it creates its zone, however the body spells it' );
    ok( $acl->authorize( token => 'owner', method => 'DELETE', path => $PATH )->{allow}, 'and deletes it' );

    is( $acl->authorize( token => 'owner', method => 'POST', path => $zones, body => { name => 'other.test.test.' } )->{allow}, 0, 'not another zone' );
    is( $acl->authorize( token => 'owner', method => 'POST', path => $zones )->{allow},                                         0, 'nor a zone that the body does not name' );
    is( $acl->authorize( token => 'owner', method => 'GET', path => $zones )->{allow},                                          0, 'nor the list of zones' );
    is( $acl->authorize( token => 'owner', method => 'GET', path => $PATH )->{allow},                                           0, 'it reads no record' );
    is( patch( 'owner', [ "web.$ZONE", 'A' ] )->{allow},                                                                        0, 'and writes none' );
    is( $acl->authorize( token => 'owner', method => 'PUT', path => $PATH, body => { kind => 'Master' } )->{allow},             0, 'nor changes the settings of the zone' );

    is( $acl->authorize( token => 'web', method => 'DELETE', path => $PATH )->{allow}, 0, 'a key that may write records cannot delete the zone' );
    is( $acl->authorize( token => 'web', method => 'POST', path => $zones, body => { name => $ZONE } )->{allow}, 0, 'nor create it' );
};

subtest 'a zone id escaped as PowerDNS escapes it' => sub {
    my $reverse = PowerDNS::API::ACL->new( store => Fake::Store->new( rev => [ { zone => '0/26.2.0.192.in-addr.arpa.', name => '*.0/26.2.0.192.in-addr.arpa.', types => ['PTR'], access => 'write' } ] ) );
    ok( $reverse->authorize( token => 'rev', method => 'GET', path => '/api/v1/servers/localhost/zones/0=2F26.2.0.192.in-addr.arpa.' )->{allow}, 'is the zone it names' );
};

like( dies { PowerDNS::API::ACL->new }, qr/needs[ ]a[ ]store/, 'new refuses to run without a store' );

done_testing;
