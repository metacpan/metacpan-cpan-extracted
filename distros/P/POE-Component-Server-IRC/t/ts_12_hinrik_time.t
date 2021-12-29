use strict;
use warnings;
use Test::More tests => 11;
use POE::Component::Server::IRC;
use POE::Component::IRC;
use POE;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config       => { sid => '6SX', },
);
my $pocoirc = POE::Component::IRC->spawn(flood => 1);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _default
            irc_001
            irc_422
            irc_391
            ircd_daemon_nick
            ircd_listener_add
            ircd_listener_del
        )],
    ],
    heap => { irc => $pocoirc, ircd => $pocosi },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $heap->{irc}->yield('register', 'all');
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $kernel->delay('_shutdown', 20);
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $heap->{irc}->yield('unregister', 'all');
    $heap->{irc}->yield('shutdown');
    $heap->{ircd}->yield('shutdown');
    delete $heap->{irc};
    delete $heap->{ircd};
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    $heap->{irc}->yield(
        connect => {
            server => 'localhost',
            port   => $port,
            nick   => 'Moo',
        },
    );
}

sub ircd_listener_del {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Stopped listener on $port");
    $_[KERNEL]->yield('_shutdown');
}

sub ircd_backend_connection {
    pass('ircd_backend_connection');
}

sub ircd_backend_auth_done {
    pass('ircd_backend_auth_done');
}

sub ircd_daemon_nick {
    pass("ircd_daemon_nick $_[ARG0]");
}

sub ircd_backend_cmd_user {
    pass('ircd_backend_cmd_user');
}

sub irc_001 {
    pass("irc_001");
    $poe_kernel->post( $_[SENDER], 'time' );
}

sub irc_391 {
    pass("irc_391");
    $poe_kernel->yield('_shutdown');
}

sub irc_422 {
    return if $_[HEAP]->{422};
    pass("irc_422");
    $_[HEAP]->{422}++;
}

sub _default {
    my $event = $_[ARG0];

    if ($event =~ /^irc_(00[1234]|25[15]|323)/ || $event eq 'irc_isupport') {
        pass($event);
    }
    elsif ($event eq 'irc_error') {
        pass($event);
        $_[HEAP]->{ircd}->del_listener(port => $_[HEAP]->{port});
    }
}
