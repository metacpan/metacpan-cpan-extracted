#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;

use Net::CLI::Interact;

my $s = new_ok('Net::CLI::Interact' => [{
    transport => 'Loopback',
    personality => 'testing',
    add_library => 't/phrasebook',
}]);

$s->set_prompt('TEST_PROMPT');

my $out = $s->cmd('TEST COMMAND');
like($out, qr/^\d{10}$/, 'sent data and command response issued');

ok(eval{$s->transport->disconnect;1}, 'transport reinitialized');

my $out2 = $s->cmd('TEST COMMAND');
like($out2, qr/^\d{10}$/, 'more sent data and command response issued');

done_testing;
