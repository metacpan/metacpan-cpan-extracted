#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>10;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy');
}

my $test_yml_loc = "test_config/sample.yml";

my $pp = Password::Policy->new(config => $test_yml_loc);

is($pp->process({ password => 'abcdef' }), 'abcdef', 'Simple plaintext password passes the default');
isa_ok(exception { $pp->process({ password => 'abc' }) }, 'Password::Policy::Exception::InsufficientLength', 'Too-short plaintext password dies with the default');

my $passwd = 'super awesome password';
is($pp->process({ password => $passwd }), 'super awesome password', 'Super awesome password passes the default');
isa_ok(exception { $pp->process({ password => $passwd, profile => 'site_moderator' }) }, 'Password::Policy::Exception::InsufficientUppercase', 'Super awesome password has no uppercase ASCII');

$passwd = 'Super Awesome Password 15';
is($pp->process({ password => $passwd }), 'Super Awesome Password 15', 'Improved super awesome password passes the default');
is($pp->process({ password => $passwd, profile => 'site_moderator' }), 'Super Awesome Password 15', 'Improved super awesome password passes site_moderator');
is($pp->process({ password => $passwd, profile => 'site_admin' }), '51 drowssaP emosewA repuS', 'Improved super awesome password passes site_admin');
isa_ok(exception { $pp->process({ password => $passwd, profile => 'grab_bag' }) }, 'Password::Policy::Exception::InsufficientNumbers', 'Improved super awesome password fails grab_bag');
note "...so we add a number, and";
$passwd = 'Super Awesome Password 150';
isa_ok(exception { $pp->process({ password => $passwd, profile => 'grab_bag' }) }, 'Password::Policy::Exception::InsufficientUppercase', 'Improved super awesome password fails grab_bag');
