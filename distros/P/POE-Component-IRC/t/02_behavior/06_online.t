use strict;
use warnings FATAL => 'all';
use POE qw(Wheel::SocketFactory);
use POE::Component::IRC;
use Socket qw(AF_INET inet_ntoa SOCK_STREAM unpack_sockaddr_in);
use Test::More tests => 5;

my $bot = POE::Component::IRC->spawn();
my $server = 'irc.freenode.net';
my $nick = "PoCoIRC" . $$;

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            _shutdown
            _success
            _failure
            _irc_connect
            _time_out
            _default
            irc_registered
            irc_connected
            irc_001
            irc_465
            irc_error
            irc_socketerr
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # Connect manually first to see if our internets are working.
    # If not, we can pass the error info to Test::More's skip()
    $heap->{sockfactory} = POE::Wheel::SocketFactory->new(
        SocketDomain   => AF_INET,
        SocketType     => SOCK_STREAM,
        SocketProtocol => 'tcp',
        RemoteAddress  => $server,
        RemotePort     => 6667,
        SuccessEvent   => '_success',
        FailureEvent   => '_failure',
    );

    $kernel->delay(_time_out => 40);
    $heap->{numeric} = 0;
    $heap->{tests} = 5;
}

sub _success {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{address} = inet_ntoa($_[ARG1]);

    $kernel->delay('_time_out');
    delete $heap->{sockfactory};
    $kernel->yield('_irc_connect');
}

sub _failure {
    my ($kernel, $heap, $operation, $errnum, $errstr)
        = @_[KERNEL, HEAP, ARG0..ARG2];

    delete $heap->{sockfactory};
    $kernel->yield(_shutdown => "$operation $errnum $errstr");
}

sub _time_out {
    delete $_[HEAP]->{sockfactory};
    $poe_kernel->yield(_shutdown => 'Connection timed out');
}

sub _shutdown {
    my ($heap, $skip) = @_[HEAP, ARG0];
    if ( !$skip && !$heap->{numeric} ) {
      $skip = 'Never received a numeric IRC event';
    }
    SKIP: {
        skip $skip, $heap->{tests} if $skip;
    }
    $poe_kernel->alarm_remove_all();
    $bot->yield('shutdown');
}

sub _irc_connect {
    my ($heap) = $_[HEAP];
    $bot->yield(register => 'all');
    $bot->yield(connect => {
        server => $heap->{address},
        nick => $nick,
    });
}

sub irc_registered {
    my ($heap, $irc) = @_[HEAP, ARG0];
    isa_ok($irc, 'POE::Component::IRC');
    $heap->{tests}--;
}

sub irc_connected {
    TODO: {
        local $TODO = "K-lines or other unforeseen issues could derail this test";
        pass('Connected');
    };
    $_[HEAP]->{tests}--;
}

sub irc_socketerr {
    my ($kernel) = $_[KERNEL];
    $kernel->yield(_shutdown => $_[ARG0] );
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    TODO: {
        local $TODO = "K-lines or other unforeseen issues could derail this test";
        pass('Logged in');
    };
    $_[HEAP]->{numeric}++;
    $_[HEAP]->{tests}--;
    $irc->yield('quit');
}

sub irc_465 {
    my $irc = $_[SENDER]->get_heap();
    TODO: {
        local $TODO = "Hey we is K-lined";
        pass('ERR_YOUREBANNEDCREEP');
    };
    $_[HEAP]->{numeric}++;
    $_[HEAP]->{tests}--;
}

sub irc_error {
    TODO: {
        local $TODO = "K-lines or other unforeseen issues could derail this test";
        pass('irc_error');
    };
    $_[HEAP]->{tests}--;
}

sub irc_disconnected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    TODO: {
        local $TODO = "K-lines or other unforeseen issues could derail this test";
        pass('Disconnected');
    };
    $heap->{tests}--;
    $kernel->yield('_shutdown');
}

sub _default {
  my ($event, $args) = @_[ARG0 .. $#_];
  return unless $event =~ m!^irc_\d+!;
  $_[HEAP]->{numeric}++;
  return;
}
