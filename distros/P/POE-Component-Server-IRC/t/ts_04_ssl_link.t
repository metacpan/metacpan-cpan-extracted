use strict;
use Test::More;
use POE::Component::Server::IRC;
use POE;

our $GOT_SSL;

BEGIN {
    eval {
        require POE::Component::SSLify;
        import POE::Component::SSLify qw( Server_SSLify SSLify_Options Client_SSLify );
        $GOT_SSL = 1;
    };
}

if (!$GOT_SSL) {
    plan skip_all => "POE::Component::SSLify not available";
}

plan tests => 14;

my $listener = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    sslify_options => ['certs/ircd.key', 'certs/ircd.crt'],
    config       => { servername => 'listen.server.irc', sid => '1FU', },
);
my $connector = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    sslify_options => ['certs/connect.key', 'certs/connect.crt'],
    config       => { servername => 'connect.server.irc', sid => '2FU', },
);

if ($listener && $connector) {
    isa_ok($listener, 'POE::Component::Server::IRC');
    isa_ok( $connector, 'POE::Component::Server::IRC');
    POE::Session->create(
        package_states => [
            main => [qw(
                _start
                _shutdown
                ircd_registered
                ircd_daemon_nick
                ircd_daemon_quit
                ircd_daemon_server
                ircd_listener_add
                ircd_listener_del) ],
        ],
        options => { trace => 0 },
        heap => { listen => $listener, connect => $connector },
    );
    $poe_kernel->run();
}

exit 0;

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{listen}->yield('register', 'all');
    $heap->{connect}->yield('register', 'all');
    my $time = time();
    $heap->{listen}->yield(
        'add_spoofed_nick',
        {
            nick    => 'fubar',
            ts      => $time,
            ircname => 'Fubar',
            umode   => 'i',
        },
    );
    $time += 10;
    $heap->{connect}->yield(
        'add_spoofed_nick',
        {
            nick    => 'fubar',
            ts      => $time,
            ircname => 'Fubar',
            umode   => 'i',
        },
    );
    $heap->{listen}->add_listener(usessl => 1);
    $kernel->delay('_shutdown', 20);
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $heap->{listen}->yield('shutdown');
    $heap->{connect}->yield('shutdown');
    delete $heap->{listen};
    delete $heap->{connect};
}

sub ircd_registered {
    my ($heap, $object) = @_[HEAP, ARG0];
    my $backend = $_[SENDER]->get_heap();
    isa_ok($object, 'POE::Component::Server::IRC');
    isa_ok($backend, 'POE::Component::Server::IRC');
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    $heap->{listen}->add_peer(
        name  => 'connect.server.irc',
        pass  => 'foo',
        rpass => 'foo',
        type  => 'c',
    );
    $heap->{connect}->add_peer(
        name     => 'listen.server.irc',
        pass     => 'foo',
        rpass    => 'foo',
        type     => 'r',
        raddress => '127.0.0.1',
        rport    => $port,
        ssl      => 1,
        auto     => 1,
    );
}

sub ircd_listener_del {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Stopped listener on $port");
    $_[KERNEL]->yield('_shutdown');
}

sub ircd_daemon_server {
    my ($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    my $ircd = $sender->get_heap();
    if ($ircd->server_name() eq 'connect.server.irc') {
        is($_[ARG0], 'listen.server.irc', $_[ARG0] . ' connected to ' . $_[ARG1]);
    }
    if ($ircd->server_name() eq 'listen.server.irc') {
        is($_[ARG0], 'connect.server.irc', $_[ARG0] . ' connected to ' . $_[ARG1]);
    }
}

sub ircd_daemon_nick {
    pass("Nick test");
}

sub ircd_daemon_quit {
    my ($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];
    pass("Kill test");
    $heap->{listen}->del_listener('port', $heap->{port});
    $kernel->state($_[STATE]);
}

