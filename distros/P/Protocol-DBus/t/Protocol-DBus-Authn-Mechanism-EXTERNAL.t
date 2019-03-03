use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;
use Test::Deep;

use Socket;

use FindBin;
use lib "$FindBin::Bin/lib";
use ClientServer;

use Protocol::DBus::Client;
use Protocol::DBus::Peer;

use Protocol::DBus::Authn::Mechanism::EXTERNAL;

my $need_socket_msghdr = Protocol::DBus::Authn::Mechanism::EXTERNAL->new()->must_send_initial();

if ($need_socket_msghdr && !ClientServer::can_socket_msghdr()) {
    plan skip_all => "This OS ($^O) needs Socket::MsgHdr to do EXTERNAL authentication.";
}

my $CLIENT_NAME = '1:1.1421';

my $client_cr = sub {
    my ($cln) = @_;

    my $client = Protocol::DBus::Client->new(
        socket => $cln,
        authn_mechanism => 'EXTERNAL',
    );

    $client->initialize();

    ok( $client->get_unique_bus_name(), 'Unique bus name is set after initialize()' );

    my $msg = $client->get_message();

    cmp_deeply(
        $msg,
        all(
            Isa('Protocol::DBus::Message'),
            methods(
                [ type_is => 'SIGNAL' ] => 1,
                [ get_header => 'PATH' ] => '/org/freedesktop/DBus',
                [ get_header => 'INTERFACE' ] => 'org.freedesktop.DBus',
                [ get_header => 'MEMBER' ] => 'NameAcquired',
                [ get_header => 'DESTINATION' ] => $CLIENT_NAME,
                [ get_header => 'SENDER' ] => 'org.freedesktop.DBus',
                [ get_header => 'SIGNATURE' ] => 's',
                get_body => [$CLIENT_NAME],
            ),
        ),
        'Client received “NameAcquired” message via get_message()',
    );
};

sub _server_finish_authn {
    my ($dbsrv) = @_;

    my $line = $dbsrv->get_line();

    is( $line, 'BEGIN', 'Client sent last line: BEGIN' );

    my $srv = Protocol::DBus::Peer->new( $dbsrv->socket() );

    my $hello = $srv->get_message();

    cmp_deeply(
        $hello,
        all(
            Isa('Protocol::DBus::Message'),
            methods(
                [ type_is => 'METHOD_CALL' ] => 1,
                [ get_header => 'PATH' ] => '/org/freedesktop/DBus',
                [ get_header => 'INTERFACE' ] => 'org.freedesktop.DBus',
                [ get_header => 'MEMBER' ] => 'Hello',
                [ get_header => 'DESTINATION' ] => 'org.freedesktop.DBus',
                get_body => undef,
            ),
        ),
        'Client sent “Hello” message',
    );

    # Test that the client receives this message from get_message().
    $srv->send_signal(
        path => '/org/freedesktop/DBus',
        interface => 'org.freedesktop.DBus',
        member => 'NameAcquired',
        destination => $CLIENT_NAME,
        sender => 'org.freedesktop.DBus',
        signature => 's',
        body => [$CLIENT_NAME],
    );

    $srv->send_return(
        $hello,
        destination => $CLIENT_NAME,
        sender => 'org.freedesktop.DBus',
        signature => 's',
        body => [$CLIENT_NAME],
    );

    return;
}

my @tests = (
    {
        skip_if => sub { $INC{'Socket/MsgHdr.pm'} && 'Socket::MsgHdr is already loaded.' },
        label => 'without unix fd',
        client => $client_cr,
        server => sub {
            my ($dbsrv) = @_;

            print "$$: in server\n";

            my $line = $dbsrv->get_line();

            my $ruid_hex = unpack('H*', $<);

            is(
                $line,
                "AUTH EXTERNAL $ruid_hex",
                'first line',
            );

            $dbsrv->send_line('OK 1234deadbeef');

            _server_finish_authn($dbsrv);
        },
    },
);

if (ClientServer::can_socket_msghdr()) {
    push @tests, {
        label => 'with unix fd',
        client => sub {
            my ($cln) = @_;

            require Socket::MsgHdr;

            $client_cr->($cln);
        },
        server => sub {
            my ($dbsrv, $peer) = @_;

            my $line = $dbsrv->get_line();

            my $ruid_hex = unpack('H*', $<);

            is(
                $line,
                "AUTH EXTERNAL $ruid_hex",
                'first line',
            );

            $dbsrv->send_line('OK 1234deadbeef');

            $line = $dbsrv->get_line();

            is( $line, 'NEGOTIATE_UNIX_FD', 'attempt to negotiate' );

            $dbsrv->send_line('AGREE_UNIX_FD');

            _server_finish_authn($dbsrv);
        },
    };
}
else {
    diag "No Socket::MsgHdr available; can’t test unix FD negotiation.";
}

ClientServer::do_tests(@tests);

done_testing();

1;
