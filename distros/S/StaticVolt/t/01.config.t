#!perl

use strict;
use warnings;

use Test::More 'tests' => 6;

use StaticVolt;

my $staticvolt = StaticVolt->new;
isa_ok $staticvolt, 'StaticVolt';

$staticvolt = StaticVolt->new(
    'includes'    => 'inc',
    'layouts'     => 'wrappers',
    'source'      => 'src',
    'destination' => 'dst',
);
isa_ok $staticvolt, 'StaticVolt';

is $staticvolt->{'includes'},    'inc',      q{custom 'includes' directory};
is $staticvolt->{'layouts'},     'wrappers', q{custom 'layouts' directory};
is $staticvolt->{'source'},      'src',      q{custom 'source' directory};
is $staticvolt->{'destination'}, 'dst',      q{custom 'destination' directory};
