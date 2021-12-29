use strict;
use warnings;
use Test::More;
use POE;
use POE::Component::Server::IRC;
use POE::Component::IRC;

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

plan tests => 17;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth           => 0,
    antiflood      => 0,
    plugin_debug   => 1,
    sslify_options => ['certs/ircd.key', 'certs/ircd.crt'],
    config         => { sid => '2FA', },
);
my $pocoirc = POE::Component::IRC->spawn(
    flood   => 1,
    UseSSL  => 1,
    SSLCert => 'certs/irc.crt',
    SSLKey  => 'certs/irc.key',
);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _default
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
    $heap->{ircd}->add_listener(usessl => 1);
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
    pass('ircd_daemon_nick');
}

sub ircd_backend_cmd_user {
    pass('ircd_backend_cmd_user');
}

sub _default {
    my $event = $_[ARG0];

    if ($event =~ /^irc_(00[1234]|25[15]|422)/ || $event eq 'irc_isupport') {
        pass($event);
    }
    elsif ($event eq 'irc_mode') {
        pass($event);
        $_[HEAP]->{irc}->yield('nick', 'moo');
    }
    elsif ($event eq 'irc_nick') {
        pass($event);
        $_[HEAP]->{irc}->yield('quit', 'moo');
    }
    elsif ($event eq 'irc_error') {
        pass($event);
        $_[HEAP]->{ircd}->del_listener(port => $_[HEAP]->{port});
    }
    elsif($event eq 'irc_snotice') {
        pass($event);
        diag($_[ARG1]->[0]);
    }
}
