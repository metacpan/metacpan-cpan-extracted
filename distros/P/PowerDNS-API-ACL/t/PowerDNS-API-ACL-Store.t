#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;
use File::Temp  qw{tempdir};
use Digest::SHA qw{sha256_hex};
use POSIX       ();

use PowerDNS::API::ACL::Store;

my $ZONE = 'lab.test.test.';

# A grant that every token here can start with.
my %OWN = ( zone => $ZONE, name => "web.$ZONE", access => 'write' );

sub fresh {
    my $dir = tempdir( CLEANUP => 1 );
    return ( PowerDNS::API::ACL::Store->new( path => "$dir/acl.db" ), "$dir/acl.db" );
}

subtest 'a token is a secret that the store keeps only a salted digest of' => sub {
    my ( $store, $path ) = fresh();
    my $secret = $store->add_token( 'web', {%OWN} );

    like( $secret, qr/\A[\w-]{40,}\z/, 'the secret is long and URL-safe' );
    isnt( $store->add_token( 'db', {%OWN} ), $secret, 'and each token gets its own' );

    # In WAL mode a commit lands in the -wal file until a checkpoint copies it.
    my $raw = join(
        q{},
        map {
            do { local ( @ARGV, $/ ) = $_; <> }
        } grep { -e } ( $path, "$path-wal" )
    );
    ok( index( $raw, $secret ) < 0,                  'the database does not hold the secret' );
    ok( index( $raw, sha256_hex($secret) ) < 0,      'nor its unsalted digest' );
    ok( index( $raw, $store->digest($secret) ) >= 0, 'only the salted one' );

    my ($other) = fresh();
    isnt( $other->digest($secret), $store->digest($secret), 'and another database salts the same secret differently' );

    my $reopened = PowerDNS::API::ACL::Store->new( path => $path );
    is( scalar $reopened->grants_for_token($secret), 1, 'the salt is kept, so the secret still works after the database is opened again' );

    like( dies { $store->add_token( 'web', {%OWN} ) }, qr/already[ ]a[ ]token/, 'a label is taken once' );
    like( dies { $store->add_token( q{},   {%OWN} ) }, qr/needs[ ]a[ ]label/,   'and a token needs one' );

    is( [ map { $_->{label} } $store->tokens ], [qw{db web}], 'tokens lists them by label' );
};

subtest 'a token that could do nothing is not made' => sub {
    my ($store) = fresh();

    like( dies { $store->add_token('web') },                                        qr/needs[ ]at[ ]least[ ]one/,    'a token with no grant is refused' );
    like( dies { $store->add_token( 'web', {%OWN}, { %OWN, access => 'admin' } ) }, qr/read,[ ]write[ ]or[ ]manage/, 'as is one with a grant that is not valid' );
    is( [ $store->tokens ], [], 'and neither left a token behind' );
};

subtest 'a grant belongs to a token and to a name in its zone' => sub {
    my ($store) = fresh();
    my $secret = $store->add_token( 'web', { zone => 'Lab.Test.Test', name => 'web.lab.test.test', types => [qw{a aaaa}], access => 'write' } );

    ok( $store->add_grant( 'web', zone => $ZONE, name => "*.svc.$ZONE", access => 'read' ), 'a grant with a pattern and no types is added' );
    ok( $store->add_grant( 'web', zone => $ZONE, name => $ZONE,         access => 'read' ), 'and one for the zone apex' );
    ok( $store->add_grant( 'web', zone => $ZONE, access => 'manage' ), 'and a manage grant, which needs no name' );

    my @grants = $store->grants('web');
    is(
        [ map { [ @{$_}{qw{zone name access}}, join( q{,}, @{ $_->{types} } ) ] } @grants ],
        [ [ $ZONE, "*.svc.$ZONE", 'read', q{*} ], [ $ZONE, $ZONE, 'read', q{*} ], [ $ZONE, $ZONE, 'manage', q{*} ], [ $ZONE, "web.$ZONE", 'write', 'A,AAAA' ] ],
        'stored canonical: lower case, the trailing dot, upper case types, * for every type, and the zone as the name of a manage grant'
    );
    is( scalar $store->grants_for_token($secret),     4,  'the secret finds the grants of its token' );
    is( [ $store->grants_for_token('not-a-secret') ], [], 'and another secret finds none' );
    is( [ $store->grants_for_token(undef) ],          [], 'nor does no secret at all' );

    like( dies { $store->add_grant( 'web',    zone => $ZONE, name => 'web.other.test.', access => 'read' ) },   qr/not[ ]in[ ]the[ ]zone/,                  'a name outside the zone is refused' );
    like( dies { $store->add_grant( 'web',    zone => $ZONE, name => 'xlab.test.test.', access => 'read' ) },   qr/not[ ]in[ ]the[ ]zone/,                  'including one that only ends with the same letters' );
    like( dies { $store->add_grant( 'web',    zone => $ZONE, name => "a.$ZONE",         access => 'manage' ) }, qr/manage[ ]grant[ ]is[ ]for[ ]the[ ]zone/, 'a manage grant for a name in the zone is refused' );
    like( dies { $store->add_grant( 'web',    zone => $ZONE, name => "a.$ZONE",         access => 'admin' ) },  qr/read,[ ]write[ ]or[ ]manage/,            'access is read, write or manage' );
    like( dies { $store->add_grant( 'nobody', zone => $ZONE, name => "a.$ZONE",         access => 'read' ) },   qr/no[ ]token[ ]labelled/,                  'and the token must exist' );
};

subtest 'removing a token takes its grants with it, and its last grant cannot go alone' => sub {
    my ( $store, $path ) = fresh();
    my $secret = $store->add_token( 'web', {%OWN} );
    $store->add_grant( 'web', zone => $ZONE, name => "*.web.$ZONE", access => 'write' );

    my ( $first, $last ) = $store->grants('web');
    ok( $store->remove_grant( $first->{id} ),  'a grant is removed by its id' );
    ok( !$store->remove_grant( $first->{id} ), 'once' );
    like( dies { $store->remove_grant( $last->{id} ) }, qr/last[ ]grant[ ]of[ ]the[ ]token[ ]web/, 'the last grant of a token is not removed' );
    is( scalar $store->grants('web'), 1, 'and is still there' );

    ok( $store->remove_token('web'),  'a token is removed' );
    ok( !$store->remove_token('web'), 'once' );
    is( [ $store->grants_for_token($secret) ], [], 'and its secret opens nothing' );

    # A second connection, as the proxy and pdns-acl each have, sees the same.
    my $again = PowerDNS::API::ACL::Store->new( path => $path );
    my $count = $again->dbh->selectrow_array('SELECT COUNT(*) FROM grants');
    is( $count, 0, 'no grant of it is left in the database' );
};

subtest 'the database is set up for more than one writer' => sub {
    my ($store) = fresh();
    my $dbh = $store->dbh;

    is( $dbh->selectrow_array('PRAGMA journal_mode'), 'wal', 'WAL, so a reader does not wait for a writer' );
    is( $dbh->selectrow_array('PRAGMA busy_timeout'), 5000,  'a lock is waited for, for five seconds' );
    is( $dbh->selectrow_array('PRAGMA synchronous'),  1,     'and a commit syncs as NORMAL does' );

    like( dies { PowerDNS::API::ACL::Store->new( path => ':memory:' ) }, qr/in[ ]memory[ ]mode,[ ]not[ ]WAL/, 'a database that cannot be in WAL mode is refused' );
};

subtest 'writers in several processes at once all succeed' => sub {
    my ( undef,    $path ) = fresh();
    my ( $writers, $each ) = ( 4, 25 );

    my @pids;
    foreach my $writer ( 1 .. $writers ) {
        my $pid = fork() // die "fork: $!";
        if ( !$pid ) {
            my $ok = eval {
                my $store = PowerDNS::API::ACL::Store->new( path => $path );
                foreach my $n ( 1 .. $each ) {
                    $store->add_token( "w$writer-$n", {%OWN}, { zone => $ZONE, name => "*.w$writer.$ZONE", access => 'write' } );
                    my ($grant) = $store->grants("w$writer-$n");
                    $store->remove_grant( $grant->{id} );
                }
                1;
            };
            warn $@ unless $ok;
            POSIX::_exit( $ok ? 0 : 1 );
        }
        push( @pids, $pid );
    }
    my @failed = grep { waitpid( $_, 0 ) && $? } @pids;

    is( scalar @failed, 0, "each of $writers writers made and changed its tokens" );
    my @tokens = PowerDNS::API::ACL::Store->new( path => $path )->tokens;
    is( scalar @tokens,                         $writers * $each, 'and every token is there' );
    is( [ grep { $_->{grants} != 1 } @tokens ], [],               'each with the one grant that is left' );
};

subtest 'a store made before a fork opens a connection of its own in the child' => sub {
    my ($store) = fresh();
    my $parent = $store->dbh;

    # What a preforking PSGI server does: load the application, then fork.
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
        my $ok = eval { $store->dbh != $parent && $store->add_token( 'child', {%OWN} ) };
        warn $@ unless $ok;
        POSIX::_exit( $ok ? 0 : 1 );
    }
    waitpid( $pid, 0 );

    is( $?,          0,       'the child wrote through a connection that is not its parent' );
    is( $store->dbh, $parent, 'the parent keeps its own' );
    ok( $store->add_token( 'parent', {%OWN} ), 'and it still works after the child is gone' );
    is( [ map { $_->{label} } $store->tokens ], [qw{child parent}], 'both writes are in the database' );
};

like( dies { PowerDNS::API::ACL::Store->new }, qr/needs[ ]a[ ]path/, 'new refuses to run without a path' );

done_testing;
