#!perl -T

use strict;
use Parse::Arcconf;
use Test::More tests => 1;

my $arcconf = Parse::Arcconf->new();
$arcconf->parse_config_file("output.txt");

ok($arcconf, "Created new Parse::Arcconf object");

