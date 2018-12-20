#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Protocol::DBus::Authn::Mechanism::EXTERNAL ();

use File::Which;

use Protocol::DBus::Client;

{
    #----------------------------------------------------------------------
    # This test can’t work without XS because the location of D-Bus’s
    # system socket is hard-coded in libdbus at compile time.
    #
    # It’s still a useful diagnostic, though.
    #----------------------------------------------------------------------

    my $dbus_send = File::Which::which('dbus-send');

    diag( "dbus-send: " . ($dbus_send || '(none)') );

    if ($dbus_send) {
        system($dbus_send, '--type=method_call', '--system', '--dest=org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus.Properties.GetAll', 'string:org.freedesktop.DBus');

        diag( "dbus-send --system worked? " . ($? ? 'no' : 'yes') );
    }

    my $client = eval {
        local $SIG{'__WARN__'} = sub { diag shift() };

        my $db = Protocol::DBus::Client->system();
        $db->initialize();
        $db;
    };
    my $err = $@;

    diag( "Client::system() worked? " . ($client ? 'yes' : 'no') );
    diag $err if !$client;

    diag( "Socket::MsgHdr loaded? " . ($INC{'Socket/MsgHdr.pm'} ? 'yes' : 'no') );
}

#----------------------------------------------------------------------

SKIP: {
    my $bin = File::Which::which('dbus-run-session') or do {
        skip 'No dbus-run-session', 1;
    };

    my $env = readpipe("$bin -- $^X -MData::Dumper -e '\$Data::Dumper::Sortkeys = 1; print Dumper \\\%ENV'");
    if ($?) {
        skip 'dbus-run-session exited nonzero', 1;
    }

    my $loaded_smh = readpipe( qq[$bin -- $^X -MProtocol::DBus::Client -e 'Protocol::DBus::Client->login_session()->initialize(); print \$INC{"Socket/MsgHdr.pm"} ? "y" : "n"'] );

    my $no_msghdr_needed = grep { $^O eq $_ } @Protocol::DBus::Authn::Mechanism::EXTERNAL::_OS_NO_MSGHDR_LIST;

    if ($no_msghdr_needed) {
        ok( !$?, 'login session bus connected!' ) or diag $env;
    }
    else {
        my $msg;

        if ($?) {
            $msg = "login_session() failed";
        }
        else {
            $msg = "login_session() worked";
        }

        skip "$msg (S::MH loaded? $loaded_smh)", 1;
    }
}

#----------------------------------------------------------------------

done_testing();
