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

ok($s->set_prompt('TEST_PROMPT'), 'set the prompt');

my $out = $s->cmd('TEST COMMAND');
like($out, qr/^\d{10}$/, 'sent data and command response issued');

ok($s->prompt_looks_like('TEST_PROMPT'), 'prompt looks like set prompt');
ok(! $s->prompt_looks_like('TEST_PROMPT_TWO'), 'prompt does not look like other');

done_testing;
