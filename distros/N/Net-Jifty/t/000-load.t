#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use_ok 'Net::Jifty';

no warnings; *Net::Jifty::login = sub { 1 }; use warnings;

my $j = Net::Jifty->new(site => 'http://mushroom.mu/', cookie_name => 'MUSHROOM_KINGDOM_SID', appname => 'MushroomKingdom', email => 'god@mushroom.mu', password => 'melange');

ok($j, "got a defined return value from Net::Jifty");
ok($j->isa('Net::Jifty'), "got a Net::Jifty object");

