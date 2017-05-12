use strict;
use warnings;
use Test::More tests => 12;
use POE::Component::Server::IRC;
use POE::Component::IRC;
use POE;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
);
my $pocoirc = POE::Component::IRC->spawn(flood => 1);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _default
            irc_001
            ircd_listener_add
        )],
    ],
    heap => { irc => $pocoirc, ircd => $pocosi },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $heap->{irc}->yield('register', 'all');
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->yield(
        'add_spoofed_nick',
        {
            nick => 'spoofed',
            umode => 'ig',
        }
    );
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
            nick   => __PACKAGE__,
        },
    );
}

sub irc_001 {
    pass("irc_001");
    $_[SENDER]->get_heap()->yield('privmsg', 'spoofed', 'foo!');
}

sub _default {
    my $event = $_[ARG0];

    if ( $event =~ /^irc_(00[234]|25[15]|422)/ || $event eq 'irc_isupport'
            || $event eq 'irc_716' || $event eq 'irc_mode') {
        pass($event);
    }
    elsif ($event eq 'irc_717') {
        pass($event);
        $poe_kernel->yield('_shutdown');
    }
}
