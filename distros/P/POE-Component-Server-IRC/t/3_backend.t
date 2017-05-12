use strict;
use warnings;
use Test::More tests => 8;
use POE::Component::Server::IRC::Backend;
use POE::Component::IRC;
use POE;

my $pocosi = POE::Component::Server::IRC::Backend->create(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
);
my $pocoirc = POE::Component::IRC->spawn(flood => 1);

if ($pocosi && $pocoirc) {
    isa_ok($pocosi, 'POE::Component::Server::IRC::Backend');
    POE::Session->create(
        package_states => [
            'main' => [qw(
                _start
                _shutdown
                ircd_connection
                ircd_cmd_nick
                ircd_cmd_user
                ircd_registered
                ircd_listener_add
                ircd_listener_del
            )],
        ],
        options => { trace => 0 },
        heap => { irc => $pocoirc, ircd => $pocosi },
    );
    $poe_kernel->run();
}

exit 0;

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $heap->{irc}->yield('register', 'all');
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $kernel->delay('_shutdown', 20);
}

sub _shutdown {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $kernel->delay('_shutdown');
    $heap->{irc}->yield('unregister', 'all');
    $heap->{irc}->yield('shutdown');
    $heap->{ircd}->yield('shutdown');
}

sub ircd_registered {
    my ($heap, $object) = @_[HEAP, ARG0];
    my $backend = $_[SENDER]->get_heap();
    isa_ok($object, 'POE::Component::Server::IRC::Backend');
    isa_ok($backend, 'POE::Component::Server::IRC::Backend');
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];

    pass("Started a listener on $port");
    $heap->{port} = $port;
    $heap->{irc}->yield(
        connect => {
            server => 'localhost',
            port   => $port,
            nick   => __PACKAGE__,
        },
    );
}

sub ircd_listener_del {
    my ($heap, $port) = @_[HEAP, ARG0];
    is($port, $heap->{port}, "Stopped listener on $port");
    $_[KERNEL]->yield('_shutdown');
}

sub ircd_connection {
    pass('ircd_backend_connection');
}

sub ircd_cmd_nick {
    pass('ircd_backend_cmd_nick');
    $_[HEAP]->{result}++;
    if ($_[HEAP]->{result} >= 2) {
        $_[HEAP]->{ircd}->del_listener('port', $_[HEAP]->{port});
    }
}

sub ircd_cmd_user {
    pass('ircd_backend_cmd_user');
    $_[HEAP]->{result}++;
    if ($_[HEAP]->{result} >= 2) {
        $_[HEAP]->{ircd}->del_listener('port', $_[HEAP]->{port});
    }
}


