#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'Test::WWW::Mechanize::Catalyst', 'Parley' );

my ($mech, $status);

$mech = Test::WWW::Mechanize::Catalyst->new;
isa_ok(
    $mech,
    'Test::WWW::Mechanize::Catalyst'
);


$mech->get_ok(
    'http://anywhere/user/login',
    'Got index page'
);

$mech->content_contains(
    'Please enter your username and password',
    'Login message in returned page content'
);


$mech->submit_form(
    fields => {
        username => 'topdog',
        password => 'k1tt3n',
    }
);

$mech->content_contains(
    'TopDog',
    'page contains forumname'
);
