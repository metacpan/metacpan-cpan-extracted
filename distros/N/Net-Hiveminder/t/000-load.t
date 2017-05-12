#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok 'Net::Hiveminder';

no warnings; *Net::Hiveminder::login = sub { 1 }; use warnings;

my $hm = Net::Hiveminder->new(email => 'god@mushroom.mu', password => 'melange');

ok($hm, "got a defined return value from Net::Hiveminder");
ok($hm->isa('Net::Hiveminder'), "got a Net::Hiveminder object");
ok($hm->isa('Net::Jifty'), "Net::Hiveminder isa Net::Jifty");

