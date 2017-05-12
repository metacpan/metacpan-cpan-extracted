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

$s->set_prompt('TEST_PROMPT_TWO'); # wrong!
ok(! eval { $s->cmd('TEST COMMAND', {timeout => 0} ) }, 'timeout of zero not accepted');
ok(! eval { $s->cmd('TEST COMMAND', {timeout => 1} ) }, 'wrong prompt causes timeout');

# need to reinit the connection
ok(eval{$s->transport->disconnect;1}, 'transport reinitialized');

my $out = $s->cmd('TEST COMMAND', {match => ['TEST_PROMPT']});
like($out, qr/^\d{10}$/, 'sent data with named custom match');

my $out2 = $s->cmd('TEST COMMAND', {match => [qr/PROMPT>/]});
like($out2, qr/^\d{10}$/, 'sent data with regexp custom match');

my $outa = $s->cmd('TEST COMMAND', {match => 'TEST_PROMPT'});
like($outa, qr/^\d{10}$/, 'sent data with named custom match, coerced');

my $out2a = $s->cmd('TEST COMMAND', {match => qr/PROMPT>/});
like($out2a, qr/^\d{10}$/, 'sent data with regexp custom match, coerced');

my $out3 = $s->cmd('TEST COMMAND', {match => [qr/PROMPT>/, qr/ANOTHER PROMPT>/]});
like($out3, qr/^\d{10}$/, 'sent data with two regexp custom matches');

done_testing;
