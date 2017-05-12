use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::MegaHAL;

unlink qw(t/megahal.dic t/megahal.brn);
my $irc = POE::Component::IRC::State->spawn( plugin_debug => 1 );

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_plugin_add irc_plugin_del irc_shutdown) ],
    ],
);

$poe_kernel->run();

sub _start {
    $irc->yield(register => 'all');

    my $plugin = POE::Component::IRC::Plugin::MegaHAL->new(
        MegaHAL_args => {
            Path => 't'
        }
    );
    isa_ok($plugin, 'POE::Component::IRC::Plugin::MegaHAL');

    if (!$irc->plugin_add('TestPlugin', $plugin)) {
        fail('plugin_add failed');
        $irc->yield('shutdown');
    }
}

sub irc_plugin_add {
    my ($name, $plugin) = @_[ARG0, ARG1];
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::MegaHAL');
  
    if (!$irc->plugin_del('TestPlugin') ) {
        fail('plugin_del failed');
        $irc->yield('shutdown');
    }
}

sub irc_plugin_del {
    my ($name, $plugin) = @_[ARG0, ARG1];
    return if $name ne 'TestPlugin';

    isa_ok($plugin, 'POE::Component::IRC::Plugin::MegaHAL');
    $irc->yield('shutdown');
}

sub irc_shutdown {
    unlink qw(t/megahal.dic t/megahal.brn);
}
