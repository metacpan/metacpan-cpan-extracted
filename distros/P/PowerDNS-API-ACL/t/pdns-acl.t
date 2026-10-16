#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

# It imports by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;    ## no critic (ProhibitUnusedImports)
use FindBin::libs;
use FindBin       ();
use File::Temp    qw{tempdir};
use Capture::Tiny qw{capture};

use PowerDNS::API::ACL::Store;

# A program has a path rather than a module name.
ok( lives { require "$FindBin::Bin/../bin/pdns-acl" }, 'the program loads as a module' ) or bail_out("bin/pdns-acl did not load: $@");    ## no critic (Modules::RequireBarewordIncludes)

my $ZONE = 'lab.test.test.';
my $db   = tempdir( CLEANUP => 1 ) . '/acl.db';

sub run {
    my @args = @_;
    my ( $out, $err, $exit ) = capture { PowerDNS::API::ACL::CLI::main( '--db', $db, @args ) };
    return ( $out, $err, $exit );
}

like( dies { run(qw{token add web}) }, qr/needs[ ]--zone/, 'token add without a grant is refused' );

my ( $secret, $exit );
( $secret, undef, $exit ) = run( qw{token add web --zone}, $ZONE, '--name', "web.$ZONE", qw{--type A --type AAAA --write} );
is( $exit, 0, 'token add with its first grant succeeds' );
chomp $secret;
ok( $secret, 'and prints the secret' );

( undef, undef, $exit ) = run( qw{grant add web --zone}, $ZONE, '--name', "*.$ZONE" );
is( $exit, 0, 'grant add succeeds' );
( undef, undef, $exit ) = run( qw{grant add web --zone}, $ZONE, '--manage' );
is( $exit, 0, 'and adds a manage grant, which needs no name' );

my ($list) = run(qw{grant list web});
like( $list, qr/^\d+\twrite\t\Q$ZONE\E\tweb[.]\Q$ZONE\E\tA,AAAA$/m, 'grant list shows the write grant with its types' );
like( $list, qr/^\d+\tread\t\Q$ZONE\E\t[*][.]\Q$ZONE\E\t[*]$/m,     'and the read grant, for every type' );
like( $list, qr/^\d+\tmanage\t\Q$ZONE\E\t\Q$ZONE\E\t[*]$/m,         'and the manage grant, for the zone itself' );

my $store = PowerDNS::API::ACL::Store->new( path => $db );
is( scalar $store->grants_for_token($secret), 3, 'the secret it printed opens those grants' );

my ($tokens) = run(qw{token list});
is( $tokens, "web\t3 grants\n", 'token list counts them' );

my ($id) = $list =~ m/^(\d+)\twrite/m;
( undef, undef, $exit ) = run( qw{grant remove}, $id );
is( $exit, 0, 'grant remove takes the id that grant list showed' );
like( dies { run( qw{grant remove}, $id ) }, qr/no[ ]grant/, 'and refuses one that is gone' );

( undef, undef, $exit ) = run(qw{token remove web});
is( $exit,                                 0,  'token remove succeeds' );
is( [ $store->grants_for_token($secret) ], [], 'and the secret opens nothing after it' );
like( dies { run(qw{token remove web}) }, qr/no[ ]token[ ]labelled[ ]web/, 'a token that is gone is refused' );

done_testing;
