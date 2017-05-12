use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 17;

{
    package SubclassIRC;
    use base qw(POE::Component::IRC);
    use Test::More;
    my $VERSION = 1;

    sub S_001 {
        my $irc1 = shift;
        $irc1->SUPER::S_001(@_);
        my $irc2 = shift;
        pass('PoCo-IRC as subclass');
        isa_ok($irc1, 'POE::Component::IRC');
        isa_ok($irc2, 'POE::Component::IRC');
        is($irc1->server_name(), 'poco.server.irc', 'Server Name Test');
        is($irc2->nick_name(), 'TestBot', 'Nick Name Test');
    }
}

my $bot = SubclassIRC->spawn(Flood => 1);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

isa_ok($bot, 'POE::Component::IRC');
isa_ok($ircd, 'POE::Component::Server::IRC');

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_registered
            irc_connected
            irc_001
            irc_whois
            irc_join
            irc_error
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel) = $_[KERNEL];

    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot->yield(register => 'all');
    $bot->yield( connect => {
        nick    => 'TestBot',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $bot->yield('shutdown');
    $ircd->yield('shutdown');
}

sub irc_registered {
    my ($irc) = $_[ARG0];
    isa_ok($irc, 'POE::Component::IRC');
}

sub irc_connected {
    pass('Connected');
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass('connect');
    is($irc->server_name(), 'poco.server.irc', 'Server Name Test');
    is($irc->nick_name(), 'TestBot', 'Nick Name Test');
    $irc->yield(whois => 'TestBot');
}

sub irc_whois {
    my ($sender, $whois) = @_[SENDER, ARG0];
    is($whois->{nick}, 'TestBot', 'Whois hash test');
    $sender->get_heap()->yield(join => '#testchannel');
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0, ARG1];
    my $nick = (split /!/, $who)[0];
    my $irc = $sender->get_heap();
    is($nick, $irc->nick_name(), 'JOINER Test');
    is($where, '#testchannel', 'Joined Channel Test');
    $irc->yield('quit');
}

sub irc_error {
    pass('irc_error');
}

sub irc_disconnected {
    my ($kernel) = $_[KERNEL];
    pass('irc_disconnected');
    $kernel->yield('_shutdown');
}
