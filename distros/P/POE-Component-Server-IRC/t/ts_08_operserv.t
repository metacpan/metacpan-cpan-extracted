use strict;
use warnings;
use Test::More tests => 12;
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use POE::Component::Server::IRC::Plugin::OperServ;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config       => { sid => '4GO', },
);

$pocosi->plugin_add(
    'OperServ',
    POE::Component::Server::IRC::Plugin::OperServ->new(),
);

my $pocoirc = POE::Component::IRC->spawn(flood => 1);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            irc_001
            irc_381
            irc_join
            ircd_listener_add
            ircd_daemon_quit
            ircd_daemon_nick
        )],
    ],
    heap => { ircd => $pocosi, irc => $pocoirc },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{ircd}->yield('register', 'all');
    $heap->{irc}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $heap->{ircd}->add_operator(
        {
            username => 'moo',
            password => 'fishdont'
        }
    );
    $kernel->delay('_shutdown', 20);
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    $heap->{irc}->yield(
        connect => {
            server => 'localhost',
            port   => $port,
            nick   => 'moo',
        },
    );
}

sub irc_001 {
    pass('Connected to ircd');
    $_[SENDER]->get_heap()->yield('oper', 'moo', 'fishdont');
}

sub irc_381 {
    pass('We are operator');
    $_[SENDER]->get_heap()->yield('join', '#test1');
}

sub irc_join {
    my ($heap, $who, $where) = @_[HEAP, ARG0..ARG1];
    my $nick = (split /!/, $who)[0];
    my $mynick = $heap->{irc}->nick_name();

    if ($where eq '#test1') {
        if ($nick eq $mynick) {
            $heap->{irc}->yield('privmsg', 'OperServ', "clear $where");
        }
        else {
        is($nick, 'OperServ', 'OperServ cleared channel');
            #$heap->{ircd}->yield('del_spoofed_nick', 'OperServ');
            $heap->{irc}->yield('join', '#test2');
        }
    }
    else {
        if ($nick eq $mynick) {
            $heap->{irc}->yield('privmsg', 'OperServ', "join $where");
        }
        else {
            is($nick, 'OperServ', 'OperServ joined channel');
            $heap->{ircd}->yield('del_spoofed_nick', 'OperServ');
        }
    }
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $heap->{irc}->yield('shutdown');
    $heap->{ircd}->yield('shutdown');
    delete $heap->{ircd};
    delete $heap->{irc};
}

sub ircd_daemon_quit {
    pass('Deleted Spoof User');
    $poe_kernel->yield('_shutdown');
}

sub ircd_daemon_nick {
    my @args = @_[ARG0..$#_];
    return if $args[0] ne 'OperServ';
    is($args[0], 'OperServ', 'Spoof Test 1: Nick');
    is($args[4], 'OperServ', 'Spoof Test 1: User');
    is($args[5], 'poco.server.irc', 'Spoof Test 1: Host');
    is($args[6], 'poco.server.irc', 'Spoof Test 1: Server');
    is($args[3], '+Doi', 'Spoof Test 1: Umode');
    is($args[7], 'The OperServ bot', 'Spoof Test 1: GECOS');
    #$_[SENDER]->get_heap()->yield( 'del_spoofed_nick', $args[0] );
}

sub _default {
    my ($event, $args) = @_[ARG0, ARG1];
    return if $event !~ /^irc_/;
    my @output = "$event: ";

    for my $arg (@$args) {
        if (ref $arg eq 'ARRAY') {
            push @output, "[" . join(", ", @$arg) . "]";
        }
        else {
            push @output, "'$arg'";
        }
    }
    print "@output\n";
    return;
}
