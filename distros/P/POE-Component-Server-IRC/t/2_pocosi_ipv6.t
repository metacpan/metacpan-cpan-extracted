use strict;
use warnings;
use Test::More;
use POE::Component::Server::IRC;
use POE::Component::IRC;
use POE;

use Socket qw( inet_pton inet_ntop pack_sockaddr_in6 unpack_sockaddr_in6 IN6ADDR_LOOPBACK SOCK_STREAM);

my $AF_INET6 = eval { Socket::AF_INET6() } or
   plan skip_all => "No AF_INET6";

# Stolen from t/05local-server-v6.t in IO-Socket-IP
# Some odd locations like BSD jails might not like IN6ADDR_LOOPBACK. We'll
# establish a baseline first to test against
my $IN6ADDR_LOOPBACK = eval {
   socket my $sockh, Socket::PF_INET6(), SOCK_STREAM, 0 or die "Cannot socket(PF_INET6) - $!";
   bind $sockh, pack_sockaddr_in6( 0, inet_pton( $AF_INET6, "::1" ) ) or die "Cannot bind() - $!";
   ( unpack_sockaddr_in6( getsockname $sockh ) )[1];
} or plan skip_all => "Unable to bind to ::1 - $@";

plan tests => 23;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config => { sid => '0CC' },
);
my $pocoirc = POE::Component::IRC->spawn(flood => 1);

if ($pocosi && $pocoirc) {
    isa_ok($pocosi, 'POE::Component::Server::IRC');
    POE::Session->create(
        package_states => [
            main => [qw(
                _start
                _shutdown
                _default
                ircd_registered
                ircd_daemon_nick
                ircd_daemon_uid
                ircd_listener_add
                ircd_listener_del) ],
        ],
        options => { trace => 0 },
        heap => { irc => $pocoirc, ircd => $pocosi },
    );
    $poe_kernel->run();
}

exit 0;

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{irc}->yield('register', 'all');
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener( bindaddr => '::1' );
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

sub ircd_registered {
    my ($heap, $object) = @_[HEAP, ARG0];
    my $backend = $_[SENDER]->get_heap();
    isa_ok($object, 'Object::Pluggable' );
    isa_ok($object, 'POE::Component::Server::IRC');
    isa_ok($backend, 'POE::Component::Server::IRC');
    isa_ok($backend->pipeline, 'Object::Pluggable::Pipeline');
}

sub ircd_listener_add {
    my ($heap, $port, $addr) = @_[HEAP, ARG0, ARG2];
    pass("Started a listener on $port $addr");
    $heap->{port} = $port;
    $heap->{irc}->yield(
        connect => {
            server  => $addr,
            port    => $port,
            nick    => __PACKAGE__,
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

sub ircd_daemon_uid {
    my @args = @_[ARG0..$#_];
    pass('ircd_daemon_uid');
    is($args[5], 'poco.server.irc', 'Expected spoofed hostname' );
    is($args[6], '0', 'IP Address should be 0' );
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
    if ($event eq 'irc_mode') {
        pass($event);
        $_[HEAP]->{irc}->yield('nick', 'moo');
    }
    if ($event eq 'irc_nick') {
        pass($event);
        $_[HEAP]->{irc}->yield('quit', 'moo');
    }
    if ($event eq 'irc_error') {
        pass($event);
        $_[HEAP]->{ircd}->del_listener('port', $_[HEAP]->{port});
    }
}
