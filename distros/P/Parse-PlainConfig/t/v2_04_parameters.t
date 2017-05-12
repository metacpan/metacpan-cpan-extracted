#!/usr/bin/perl -T
# 04_parameters.t

use Test::More tests => 8;
use Paranoid;
use Parse::PlainConfig::Legacy;

use strict;
use warnings;

psecureEnv();

my $testrc = "./t/v2_testrc";
my $conf   = Parse::PlainConfig::Legacy->new(FILE => $testrc);
my @test   = ("SCALAR 1", "SCALAR 2", "SCALAR 3", "LIST 1", "LIST 2",
              "HASH 1");
my (@params, $p);

# 1 Make sure parameters have been read
ok( $conf->read, 'read 1');
@params = $conf->parameters;
is( scalar(@params), 10, '# of parameters read' );

foreach my $t (@test) {
    ($p) = grep /^\Q$t\E$/, @params;
    is( $p, $t, "parameter $t" );
}

# end 04_parameters.t
