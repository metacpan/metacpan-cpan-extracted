#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>5;

BEGIN {
    use_ok('Password::Policy');
}

my $test_yml_loc = "test_config/sample.yml";

my $pp = Password::Policy->new(config => $test_yml_loc);

is_deeply(
    $pp->rules,
    {
        algorithm => 'Plaintext',
        length => 4
    },
    'Default profile'
);

is_deeply(
    $pp->rules('site_moderator'),
    {
        algorithm => 'Plaintext',
        length => 8,
        uppercase => 1
    },
    'Site moderator profile'
);

is_deeply(
    $pp->rules('site_admin'),
    {
        algorithm => 'ROT13',
        length => 10,
        numbers => 2,
        uppercase => 1
    },
    'Site admin profile'
);

is_deeply(
    $pp->rules('grab_bag'),
    {
        algorithm => 'ROT13',
        length => 15,
        lowercase => 6,
        numbers => 3,
        uppercase => 4,
        whitespace => 2
    },
    'Grab Bag profile'
);
