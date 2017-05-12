use strict;
use warnings;
use POE qw(Wheel::SocketFactory);
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 7;

my $bot1 = POE::Component::IRC->spawn(
    plugin_debug => 1,
    flood        => 1,
    alias        => 'bot1',
);
my $bot2 = POE::Component::IRC->spawn(
    plugin_debug => 1,
    flood        => 1,
    alias        => 'bot2',
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth         => 0,
    AntiFlood    => 0,
    plugin_debug => 1,
);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_mode
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $heap->{count} = 0;
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot1->yield(register => 'all');
    $bot1->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
        ircname => 'Test test bot',
    });

    $bot2->yield(register => 'all');
    $bot2->yield(connect => {
        nick    => 'TestBot2',
        server  => '127.0.0.1',
        port    => $port,
        ircname => 'Test test bot',
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass($irc->session_alias() . ' logged in');
    $irc->yield( 'join', '#testchannel' );
}

sub irc_join {
    my $irc = $_[SENDER]->get_heap();
    my $nick = (split /!/, $_[ARG0])[0];
    return if lc( $nick ) eq lc( $irc->nick_name );
    pass($irc->session_alias() . ' joined channel');
    $irc->yield( 'mode', '#testchannel', '+o', $nick );
}

sub irc_mode {
    return unless $_[ARG1] =~ /^\#/ and $_[ARG2] =~ /o/;
    my $irc = $_[SENDER]->get_heap();
    pass($irc->session_alias() . ' received a mode message');
    $irc->yield( 'quit' );
}

sub irc_disconnected {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    my $irc = $sender->get_heap();

    pass($irc->session_alias() . ' disconnected');
    $heap->{count}++;
    $kernel->yield('_shutdown') if $heap->{count} == 2;
}

sub _shutdown {
    my ($kernel) = $_[KERNEL];

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
}

