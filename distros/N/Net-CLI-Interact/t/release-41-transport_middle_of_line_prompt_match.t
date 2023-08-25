#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

{
    package # hide from pause
        Net::CLI::Interact::Transport::LoopbackMiddleOfLinePrompt;

    use Moo;
    extends 'Net::CLI::Interact::Transport::Loopback';

    sub runtime_options {
        return ('-ne', 'BEGIN { $| = 1 }; use Time::HiRes qw( sleep ); print "some line\n looks-like-prompt#"; sleep(0.01); print "additional-characters\nPROMPT#";');
    }
}

use strict; use warnings FATAL => 'all';
use Test::More 0.88;
use Test::File::ShareDir::Dist { "Net-CLI-Interact" => "share" };

use Net::CLI::Interact;

my $s = new_ok('Net::CLI::Interact' => [{
    transport => 'LoopbackMiddleOfLinePrompt',
    personality => 'ios',
}]);

# uncomment for debugging
# $s->set_global_log_at('debug');

$s->set_prompt('privileged');

my $out = $s->cmd('show running-config');
is($out, "some line\n looks-like-prompt#additional-characters\n", 'full response returned');
is($s->last_prompt, 'PROMPT#');

done_testing;