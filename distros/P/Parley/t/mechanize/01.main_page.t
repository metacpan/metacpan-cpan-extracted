#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'Test::WWW::Mechanize::Catalyst', 'Parley' );

my $mech = Test::WWW::Mechanize::Catalyst->new;
isa_ok($mech, 'Test::WWW::Mechanize::Catalyst');

$mech->get_ok("http://anywhere/", 'Got index page');
$mech->content_contains('Forum List', 'Default page is the forum list');
