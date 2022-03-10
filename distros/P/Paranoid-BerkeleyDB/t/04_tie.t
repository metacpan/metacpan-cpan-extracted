#!/usr/bin/perl -T

use Test::More tests => 24;
use Paranoid;
use Paranoid::Debug;
use Paranoid::BerkeleyDB;

use strict;
use warnings;

psecureEnv();

my ( $rv, $db, $adb, $pid, $prv, %test, %test2, @keys, @c, $k, $v );

mkdir './t/db';

#PDEBUG = 20;

# OO invocation tests
$db = new Paranoid::BerkeleyDB Home => './t/db';
ok( !defined $db, 'invalid invocation - 1' );
$db = new Paranoid::BerkeleyDB Db => { '-Filename' => './t/db/test.db' };
ok( defined $db, 'good invocation - 2' );
$db = new Paranoid::BerkeleyDB
    Home     => './t/db-env',
    Filename => './t/db/test.db';
ok( defined $db, 'good invocation - 3' );
my $env = new Paranoid::BerkeleyDB::Env '-Home' => './t/db';
$db = new Paranoid::BerkeleyDB
    Env      => $env,
    Filename => './t/db/test.db';
ok( defined $db, 'good invocation - 4' );

$env = $db = undef;

# tie tests
$rv = tie %test, 'Paranoid::BerkeleyDB', Filename => './t/db/test.db';
ok( $rv, 'tie - 5' );
$rv = tie %test2, 'Paranoid::BerkeleyDB', Filename => './t/db/test2.db';
ok( $rv,                'tie 2 - 5' );
ok( !exists $test{foo}, 'tie exist - 6' );
$test{foo} = "bar";
$test{roo} = "foo";
ok( exists $test{foo}, 'tie store/exist - 7' );
ok( exists $test{roo}, 'tie store/exist - 8' );
is( $test{foo}, 'bar', 'tie fetch - 9' );
is( $test{roo}, 'foo', 'tie fetch - 10' );
$test2{foo} = "bar";
$test2{roo} = "foo";
ok( exists $test2{foo}, 'tie 2 store/exist - 7' );
ok( exists $test2{roo}, 'tie 2 store/exist - 8' );
is( $test2{foo}, 'bar', 'tie 2 fetch - 9' );
is( $test2{roo}, 'foo', 'tie 2 fetch - 10' );

@keys = keys %test;
is( @keys, 2, 'tie first/next key - 11' );
while ( ( $k, $v ) = each %test ) {
    push @c, $k, $v;
}
is( @c,           4, 'tie first/next key/value - 12' );
is( scalar %test, 1, 'tie scalar - 13' );
%test = ();
is( scalar %test, 0, 'tie clear/scalar - 14' );

%test = ();
$rv = untie %test and untie %test2;
ok( $rv, 'untie - 15' );

# forked tests

# Prep
@c = ();
foreach ( 1 .. 4 ) {
    push @c, [];
    @keys = ( 0 .. 10000 );
    while (@keys) {
        push @{ $c[-1] }, splice @keys, int rand @keys, 1;
    }
}

while (@c) {
    @keys = @{ shift @c };
    unless ( $pid = fork ) {

        # Child process
        $rv = tie %test, 'Paranoid::BerkeleyDB', Filename => './t/db/test.db';
        foreach (@keys) {
            my $dref = tied %test;
            my $lock = $dref->cds_lock;
            $test{$_} = "$_-$$";
            $lock->cds_unlock;
        }
        untie %test;
        exit 0;
    }
}

for ( 1 .. 4 ) {
    wait;
    $prv = $?;
    is( $prv, 0, 'clean exit in child' );
}

# Cleanup
system 'rm -rf t/db*';

