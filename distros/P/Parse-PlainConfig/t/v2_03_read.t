#!/usr/bin/perl -T
# 03_read.t

use Test::More tests => 3;
use Paranoid;
use Parse::PlainConfig::Legacy;

use strict;
use warnings;

psecureEnv();

my $testrc = "./t/v2_testrc";
my $conf   = new Parse::PlainConfig::Legacy;
my @p;

ok( !$conf->read( "${testrc}-1" ), 'read 1' );
ok( $conf->read( $testrc ), 'read 2' );
@p = $conf->parameters;
is( scalar( grep( /^SCALAR 1$/, @p ) ), 1, 'check parameters' );

# end 03_read.t
