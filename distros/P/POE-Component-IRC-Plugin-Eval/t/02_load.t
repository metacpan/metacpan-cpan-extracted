use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use JSON::Any";
    plan skip_all => "JSON::Any couldn't be loaded" if $@;
}

use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::BotCommand;
use POE::Component::IRC::Plugin::Eval;

plan tests => 3;

my $irc = POE::Component::IRC::State->spawn( plugin_debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_plugin_add irc_plugin_del) ],
    ],
);

$poe_kernel->run();

sub _start {
    $irc->yield(register => 'all');

    my $botcmd = POE::Component::IRC::Plugin::BotCommand->new();
    $irc->plugin_add('BotCmd', $botcmd);

    my $plugin = POE::Component::IRC::Plugin::Eval->new(
        Channels    => ['#foo'],
    );
    isa_ok($plugin, 'POE::Component::IRC::Plugin::Eval');

    if (!$irc->plugin_add('TestPlugin', $plugin)) {
        fail('plugin_add failed');
        $irc->yield('shutdown');
    }
}

sub irc_plugin_add {
    my ($name, $plugin) = @_[ARG0, ARG1];
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::Eval');
  
    if (!$irc->plugin_del('TestPlugin') ) {
        fail('plugin_del failed');
        $irc->yield('shutdown');
    }
}

sub irc_plugin_del {
    my ($name, $plugin) = @_[ARG0, ARG1];
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::Eval');
    $irc->yield('shutdown');
}
