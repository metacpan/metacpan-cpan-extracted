use strict;
use warnings;
use Test::More tests => 31;
use POE::Component::Server::IRC;
use POE::Component::IRC;
use POE;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
);
my @pocoirc;
push @pocoirc, POE::Component::IRC->spawn(alias => $_, flood => 1) for qw(one two);

if ($pocosi && @pocoirc) {
    isa_ok( $pocosi, "POE::Component::Server::IRC" );
    POE::Session->create(
        package_states => [
            'main' => [qw(
                _start
                _shutdown
                _default
                ircd_registered
                ircd_daemon_nick
                ircd_listener_add
                ircd_listener_del) ],
        ],
        options => { trace => 0 },
        heap => { irc => \@pocoirc, ircd => $pocosi },
    );
    $poe_kernel->run();
}

exit 0;

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $_->yield('register', 'all') for @{ $heap->{irc} };
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $kernel->delay('_shutdown', 20);
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $_->yield('shutdown') for @{ $heap->{irc} };
    $heap->{ircd}->yield('shutdown');
    delete $heap->{irc};
    delete $heap->{ircd};
}

sub ircd_registered {
    my ($heap, $object) = @_[HEAP,ARG0];
    my $backend = $_[SENDER]->get_heap();
    isa_ok($object, 'POE::Component::Server::IRC');
    isa_ok($backend, 'POE::Component::Server::IRC');
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    $_->yield(
        connect => {
            server => 'localhost',
            port   => $port,
            nick   => "foo" . $_->session_alias(),
        },
    ) for @{ $heap->{irc} };
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
    ok('ircd_backend_auth_done');
}

sub ircd_daemon_nick {
    pass('ircd_daemon_nick');
}

sub ircd_backend_cmd_user {
    pass('ircd_backend_cmd_user');
}

sub _default {
    my $event = $_[ARG0];
    my $sender = $_[SENDER]->ID();
    return 0 if $sender eq $poe_kernel->ID();
    my $irc = $_[SENDER]->get_heap();

    if ($event =~ /^irc_(00[1234]|25[15]|422)/ || $event eq 'irc_isupport') {
        pass($event);
    }
    if ($event eq 'irc_mode') {
        pass($event);
        $irc->yield('nick', 'moo' . $sender);
    }
    if ($event eq 'irc_nick') {
        pass($event);
        $irc->yield('quit', 'moo' . $sender);
    }
    if ($event eq 'irc_error') {
        pass($event);
        $_[HEAP]->{quit}++;
        $_[HEAP]->{ircd}->del_listener('port', $_[HEAP]->{port}) if $_[HEAP]->{quit} == 2;
    }
    return 0;
}
