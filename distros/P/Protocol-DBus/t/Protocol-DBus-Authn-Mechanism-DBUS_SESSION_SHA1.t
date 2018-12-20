#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use File::Spec;
use File::Temp;

use FindBin;
use lib "$FindBin::Bin/lib";
use ClientServer;

use Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces;

use Protocol::DBus::Authn;

# So we can mock below.
use Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1;

$| = 1;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $username = 'Felipe Gasper';

no warnings 'redefine';
local *Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::_getpw = sub {
    return ( $username, (undef) x 6, $dir );
};

local *Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::_create_challenge = sub {
    return '7730cae01febddd7d123a52a8d742dc212930dde';
};

my $keyrings_dir = File::Spec->catfile($dir, Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces::KEYRINGS_DIR());

mkdir $keyrings_dir;

my @tests = (
    {
        label => 'without unix fd',
        client => sub {
            my ($cln) = @_;

            my $authn = Protocol::DBus::Authn->new(
                socket => $cln,
                mechanism => 'DBUS_COOKIE_SHA1',
            );

            $authn->go();
        },
        server => sub {
            my ($dbsrv) = @_;
            my $line = $dbsrv->get_line();

            my $ruid_hex = unpack('H*', $username);

            is(
                $line,
                "AUTH DBUS_COOKIE_SHA1 $ruid_hex",
                'first line',
            );

            {
                open my $wfh, '>>', "$keyrings_dir/org_freedesktop_general";
                printf {$wfh} "%s %s %s$/", 1240694009, time, 'b0fa6f735d59ed7bd0394faaa04d6f78adcbe258bd90b050';
            }

            $dbsrv->send_line('DATA 6f72675f667265656465736b746f705f67656e6572616c2031323430363934303039206634376636313633643563633432306433616163313333363838303961646463');

            $line = $dbsrv->get_line();

            is(
                $line,
                'DATA 373733306361653031666562646464376431323361353261386437343264633231323933306464652066373737333337623064613830633238363835376163343830613737353864353239346533376231',
                'client response',
            );

            $dbsrv->send_line('OK 1234deadbeef');

            $line = $dbsrv->get_line();

            is( $line, 'BEGIN', 'last line: BEGIN' );
        },
    },
);

if (ClientServer::can_socket_msghdr()) {
    push @tests, {
        label => 'with unix fd',
        client => sub {
            my ($cln) = @_;

            require Socket::MsgHdr;

            my $authn = Protocol::DBus::Authn->new(
                socket => $cln,
                mechanism => 'DBUS_COOKIE_SHA1',
            );

            $authn->go();
        },
        server => sub {
            my ($dbsrv) = @_;
            my $line = $dbsrv->get_line();

            my $ruid_hex = unpack('H*', $username);

            is(
                $line,
                "AUTH DBUS_COOKIE_SHA1 $ruid_hex",
                'first line',
            );

            {
                open my $wfh, '>>', "$keyrings_dir/org_freedesktop_general";
                printf {$wfh} "%s %s %s$/", 1240694009, time, 'b0fa6f735d59ed7bd0394faaa04d6f78adcbe258bd90b050';
            }

            $dbsrv->send_line('DATA 6f72675f667265656465736b746f705f67656e6572616c2031323430363934303039206634376636313633643563633432306433616163313333363838303961646463');

            $line = $dbsrv->get_line();

            is(
                $line,
                'DATA 373733306361653031666562646464376431323361353261386437343264633231323933306464652066373737333337623064613830633238363835376163343830613737353864353239346533376231',
                'client response',
            );

            $dbsrv->send_line('OK 1234deadbeef');

            $line = $dbsrv->get_line();

            is( $line, 'NEGOTIATE_UNIX_FD', 'negotiate unix FD passing' );

            $dbsrv->send_line('AGREE_UNIX_FD');

            $line = $dbsrv->get_line();

            is( $line, 'BEGIN', 'last line: BEGIN' );
        },
    };
}
else {
    diag "No Socket::MsgHdr available; can’t test unix FD negotiation.";
}

ClientServer::do_tests(@tests);

done_testing();
