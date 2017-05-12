#!/usr/bin/perl -T
# 01_ini.t

use Test::More tests => 2;
use Paranoid;
use Parse::PlainConfig::Legacy;

use strict;
use warnings;

psecureEnv();

my $conf;

$conf = Parse::PlainConfig::Legacy->new( 'PARAM_DELIM' => '=', PADDING => 1 );
isnt( $conf, undef, 'constructor 3' );
isa_ok( $conf, 'Parse::PlainConfig::Legacy', 'constructor 4' );

# end 01_ini.t
