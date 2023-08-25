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

my $s = new_ok('Net::CLI::Interact' => [{
    transport => 'Loopback',
    personality => 'testing',
    add_library => 't/phrasebook',
}]);

my $pb = $s->phrasebook;


ok(eval { $pb->prompt('TEST_PROMPT_ONE') }, 'prompt exists');
ok(! eval { $pb->prompt('TEST_PROMPT_XXX') }, 'prompt does not exist');

my $p = $pb->prompt('TEST_PROMPT_ONE');
isa_ok($p, 'Net::CLI::Interact::ActionSet');

ok(eval { $pb->macro('TEST_MACRO_ONE') }, 'macro exists');
ok(! eval { $pb->macro('TEST_MACRO_XXX') }, 'macro does not exist');

my $m = $pb->macro('TEST_MACRO_ONE');
isa_ok($m, 'Net::CLI::Interact::ActionSet');

ok($s->set_phrasebook({ personality => 'fwsm3' }), 'new phrasebook loaded');
$pb = $s->phrasebook;

ok(eval { $pb->prompt('generic') }, 'prompt exists');
ok(! eval { $pb->prompt('generic_XXX') }, 'prompt does not exist');

my $p2 = $pb->prompt('privileged');
isa_ok($p2, 'Net::CLI::Interact::ActionSet');

ok(eval { $pb->macro('begin_privileged') }, 'macro exists');
ok(! eval { $pb->macro('begin_privileged_XXX') }, 'macro does not exist');

my $m2 = $pb->macro('end_privileged');
isa_ok($m2, 'Net::CLI::Interact::ActionSet');

ok($s->set_phrasebook({ personality => 'blah' }), 'new phrasebook loaded');
$pb = $s->phrasebook;

ok(eval { $pb->prompt('blahblah') }, 'local prompt exists');
ok(eval { $pb->prompt('err_string') }, 'remote prompt exists');

done_testing;
