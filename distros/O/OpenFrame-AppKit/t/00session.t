#!/usr/bin/perl -w

use strict;
use lib './lib';
use OpenFrame::AppKit::Session;
use Test::More tests => 7;

ok(my $session = OpenFrame::AppKit::Session->new(), "session created ok");
ok(my $id = $session->id(), "got id okay");
ok($session->store(), "stored session okay");
is($session->get('colour'), undef, "fetched undefined value");
ok($session->set('colour', 'orange'), "set value");
is($session->get('colour'), 'orange', "fetched value");

ok(my $s2 = OpenFrame::AppKit::Session->fetch( $id ), "got session ok");

1;
