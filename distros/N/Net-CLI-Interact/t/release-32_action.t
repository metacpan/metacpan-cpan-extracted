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

my $s = Net::CLI::Interact->new({
    transport => 'Loopback',
    personality => 'testing',
    add_library => 't/phrasebook',
});

my $pb = $s->phrasebook;
my $m = $pb->macro('TEST_PROMPT_TWO');

ok($m->clone, 'clone method');
my $m2 = $m->clone;
isa_ok($m2, 'Net::CLI::Interact::ActionSet');

isa_ok($m2->item_at(-1), 'Net::CLI::Interact::Action');
my $a = $m2->item_at(-1);

is($a->type, 'match', 'is a match');
is($a->value->[0] .'', qr/TEST_PROMPT_TWO$/, 'regexp matches');
is($a->num_params, 0, 'no params');

my $m3 = $pb->macro('TEST_MACRO_PARAMS');
my $a2 = $m3->item_at(-1);

is($a2->type, 'match', 'is a match');
is($a2->value->[0] .'', qr/^.+$/, 'regexp matches');
is($a2->num_params, 0, 'no params');

my $a3 = $m3->item_at(-2);

is($a3->type, 'send', 'is a send');
is($a3->value, 'param %s param %s', 'send value matches');
is($a3->num_params, 2, 'two params');

done_testing;
