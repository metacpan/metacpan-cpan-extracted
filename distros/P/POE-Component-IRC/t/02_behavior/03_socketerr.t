use strict;
use warnings FATAL => 'all';
use POE qw(Wheel::SocketFactory);
use POE::Component::IRC;
use Socket qw(unpack_sockaddr_in);
use Test::More tests => 1;

my $bot = POE::Component::IRC->spawn();

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            _try_connect
            _shutdown
            irc_socketerr
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel) = $_[KERNEL];

    my $port = get_port() or $kernel->yield(_shutdown => 'No free port');
    $kernel->yield(_try_connect => $port);
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub get_port {
    my $wheel = POE::Wheel::SocketFactory->new(
        BindAddress  => '127.0.0.1',
        BindPort     => 0,
        SuccessEvent => '_fake_success',
        FailureEvent => '_fake_failure',
    );

    return if !$wheel;
    return unpack_sockaddr_in($wheel->getsockname()) if wantarray;
    return (unpack_sockaddr_in($wheel->getsockname))[0];
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $bot->yield(unregister => 'socketerr');
    $bot->yield('shutdown');
}

sub _try_connect {
    my ($port) = $_[ARG0];

    $bot->yield(register => 'socketerr');
    $bot->yield( connect => {
        nick => 'TestBot',
        server => '127.0.0.1',
        port => $port,
    });
}

sub irc_socketerr {
    my ($kernel) = $_[KERNEL];
    pass('Socket Error');
    $kernel->yield('_shutdown');
}
