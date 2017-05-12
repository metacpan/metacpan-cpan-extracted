#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>4;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy');
}

my $test_yml_loc = "test_config/sample.yml";

my $pp = Password::Policy->new(config => $test_yml_loc, previous => [ 'abcdef', 'abcdefg' ]);

isa_ok(exception { $pp->process({ password => 'abcdef' }) }, 'Password::Policy::Exception::ReusedPassword', 'Used that password before');
isa_ok(exception { $pp->process({ password => 'abcdefg' }) }, 'Password::Policy::Exception::ReusedPassword', 'Used that password before too');
is($pp->process({ password => 'abcdefgh' }), 'abcdefgh', 'Have not used this one before');
