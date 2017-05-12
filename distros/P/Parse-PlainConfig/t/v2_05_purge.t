#!/usr/bin/perl -T
# 05_purge.t

use Test::More tests => 10;
use Paranoid;
use Parse::PlainConfig::Legacy;

use strict;
use warnings;

psecureEnv();

my $testrc = "./t/v2_testrc";
my $conf   = Parse::PlainConfig::Legacy->new(FILE => $testrc);
my (@params, $p);

ok( $conf->read, 'read 1' );
@params = $conf->parameters;
ok( scalar @params > 1, 'has parameters 1' );
ok( $conf->purge, 'purge 1');
@params = $conf->parameters;
ok( scalar @params == 0, 'has parameters 2' );

$conf = Parse::PlainConfig::Legacy->new(
    FILE        => $testrc,
    DEFAULTS    => {
        'SCALAR 1'  => 'foo',
        'SCALAR 2'  => 'bar',
        'UNDEC'     => 5,
        },
    );
ok( $conf->read, 'read 2' );
ok( $conf->purge, 'purge 2');
@params = $conf->parameters;
ok( scalar @params > 1, 'has parameters 3' );
($p) = grep /^UNDEC$/, @params;
ok( $p eq 'UNDEC', 'has default parameter' );
is( $conf->parameter( 'UNDEC' ), 5, 'default param value match' );
@params = $conf->parameters;
ok( scalar @params == 3, 'has parameters 4' );

# end 05_purge.t
