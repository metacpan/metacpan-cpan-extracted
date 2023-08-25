#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;
use Test::File::ShareDir::Dist { "Net-CLI-Interact" => "share" };

use Net::CLI::Interact;

my $s = Net::CLI::Interact->new({
    transport => 'Loopback',
    personality => 'testing',
    add_library => 't/phrasebook',
});

my $pb = $s->phrasebook;
my $p = $pb->prompt('TEST_PROMPT_ONE');

ok($p->clone, 'clone method');
my $p2 = $p->clone;
isa_ok($p2, 'Net::CLI::Interact::ActionSet');

ok($p2->current_match(qr//), 'current_match method');
ok($p2->register_callback(sub{}), 'register_callback method');
ok(eval{ $p2->execute ;1}, 'execute method does not blow up');
ok(eval{ $p2->apply_params ;1}, 'empty apply_params');

my $p3 = $pb->macro('TEST_MACRO_PARAMS');

ok($p3->clone, 'clone method');
my $p4 = $p3->clone;
isa_ok($p4, 'Net::CLI::Interact::ActionSet');

ok($p4->current_match(qr//), 'current_match method');
ok($p4->register_callback(sub{}), 'register_callback method');

$p4->apply_params(0, 1);
ok(eval{ $p4->execute ;1}, 'execute method does not blow up');

ok(eval{ $p4->apply_params ;1}, 'empty apply_params');
ok(eval{ $p4->apply_params(qr/a b c d/) ;1}, 'method apply_params');

done_testing;
