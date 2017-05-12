use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::PlugMan;
use Test::More tests => 8;

{
    package MyPlugin;
    use POE::Component::IRC::Plugin qw( :ALL );

    sub new {
        return bless { @_[1..$#_] }, $_[0];
    }

    sub PCI_register {
        $_[1]->plugin_register($_[0], 'SERVER', qw(all));
        return 1;
    }

    sub PCI_unregister {
        return 1;
    }

    sub _default {
        return PCI_EAT_NONE;
    }
}

my $bot = POE::Component::IRC::State->spawn( plugin_debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw(
            _start
            irc_plugin_add
            irc_plugin_del
        )],
    ],
);

$poe_kernel->run();

sub _start {
    $bot->yield(register => 'all');

    my $plugin = POE::Component::IRC::Plugin::PlugMan->new();
    isa_ok($plugin, 'POE::Component::IRC::Plugin::PlugMan');

    if (!$bot->plugin_add('TestPlugin', $plugin)) {
        fail('plugin_add failed');
        $bot->yield('shutdown');
    }
}

sub irc_plugin_add {
    my ($sender, $name, $plugin) = @_[SENDER, ARG0, ARG1];
    my $irc = $sender->get_heap();
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::PlugMan');

    ok($plugin->load('Test1', 'POE::Component::IRC::Test::Plugin'), 'PlugMan_load');
    ok($plugin->reload('Test1'), 'PlugMan_reload');
    ok($plugin->unload('Test1'), 'PlugMan_unload');

    ok($plugin->load('Test2', MyPlugin->new()), 'PlugMan2_load');
    ok($plugin->unload('Test2'), 'PlugMan2_unload');

    if (!$irc->plugin_del('TestPlugin')) {
        fail('plugin_del failed');
        $irc->yield('shutdown' );
    }
}

sub irc_plugin_del {
    my ($sender, $name, $plugin) = @_[SENDER, ARG0, ARG1];
    my $irc = $sender->get_heap();
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::PlugMan');

    $irc->yield('shutdown');
}

