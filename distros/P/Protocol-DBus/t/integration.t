#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

use Protocol::DBus::Authn::Mechanism::EXTERNAL ();

use File::Which;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBusSession;

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

        my $db = Protocol::DBus::Client::system();
        $db->initialize();
        $db;
    };
    my $err = $@;

    diag( "Client::system() worked? " . ($client ? 'yes' : 'no') );
    diag $err if !$client;

    diag( "Socket::MsgHdr loaded? " . ($INC{'Socket/MsgHdr.pm'} ? 'yes' : 'no') );
}

#----------------------------------------------------------------------

# Ensure that we test with the intended version of Protocol::DBus …
my @incargs = map { "-I$_" } @INC;

my $dbus_run_session_bin;

SKIP: {
    my $bin = DBusSession::get_bin_or_skip();

    my $env = readpipe("$bin -- $^X -MData::Dumper -e '\$Data::Dumper::Sortkeys = 1; print Dumper \\\%ENV'");
    if ($?) {
        skip 'dbus-run-session exited nonzero', 1;
    }

    $dbus_run_session_bin = $bin;

    diag "dbus-run-session OK: $bin";

    my $loaded_smh = readpipe( qq[$bin -- $^X @incargs -MProtocol::DBus::Client -e 'Protocol::DBus::Client::login_session()->initialize(); print \$INC{"Socket/MsgHdr.pm"} ? "y" : "n"'] );

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

SKIP: {
    my $tests = 4;

    DBusSession::skip_if_lack_needed_socket_msghdr(4);

    if (!$dbus_run_session_bin) {
        diag 'No usable dbus-run-session; trying login session anyway …';

        require Protocol::DBus::Client;
        my $ok = eval {
            Protocol::DBus::Client::login_session()->initialize();
            1;
        };

        if ($ok) {
            diag "Login session OK; proceeding with tests.";
        }
        else {
            skip 'Can’t find a login session; skipping.', $tests;
        }
    }

    my $sess = DBusSession->new();

    _test_anyevent();
    _test_ioasync();
    _test_mojo();

    _test_unix_fds();
}

sub _test_unix_fds {
    SKIP: {
        eval { require Socket::MsgHdr };

        my $dbus1 = Protocol::DBus::Client::login_session();
        $dbus1->initialize();

        skip 'Unix FDs are unsupported.', 1 if !$dbus1->supports_unix_fd();

        my $dbus2 = Protocol::DBus::Client::login_session();
        $dbus2->initialize();

        my ($pr, $pw);
        pipe $pr, $pw;

        my $interface = 'org.whatever' . sprintf('%x', substr(rand, 2));

        $dbus1->send_signal(
            interface => $interface,
            member => 'passfd',
            signature => 'h',
            path => '/org/whatever',
            destination => $dbus2->get_unique_bus_name(),
            body => [ $pw ],
        );

        my $dup_fh;

        while ( my $msg = $dbus2->get_message() ) {
            next if !$msg->type_is('SIGNAL');

            next if $msg->get_header('INTERFACE') ne $interface;

            ($dup_fh) = @{ $msg->get_body() };

            last;
        }

        syswrite $dup_fh, 'x';
        close $dup_fh;
        close $pw;

        sysread $pr, my $buf, 1;

        is( $buf, 'x', 'UNIX FD passing works' );
    }
}

sub _test_anyevent {
    SKIP: {
        skip 'No usable AnyEvent', 1 if !eval { require AnyEvent };

        diag "Testing AnyEvent ($AnyEvent::VERSION) …";

        require Protocol::DBus::Client::AnyEvent;

        my $ok = eval {
            my $dbus = Protocol::DBus::Client::AnyEvent::login_session();

            my $cv = AnyEvent->condvar();
            $dbus->initialize()->finally($cv);
            $cv->recv();

            1;
        };

        my $err = $@;

        ok( $ok, 'AnyEvent can initialize()' ) or diag explain $err;
    }
}

sub _test_ioasync {
    SKIP: {
        skip 'No usable IO::Async', 1 if !eval { require IO::Async::Loop };

        diag "Testing IO::Async ($IO::Async::Loop::VERSION) …";

        require Protocol::DBus::Client::IOAsync;

        my $ok = eval {
            my $loop = IO::Async::Loop->new();
            my $dbus = Protocol::DBus::Client::IOAsync::login_session($loop);

            $dbus->initialize()->finally( sub { $loop->stop() } );
            $loop->run();

            1;
        };

        my $err = $@;

        ok( $ok, 'IO::Async can initialize()' ) or diag explain $err;
    }
}

sub _test_mojo {
    SKIP: {
        skip 'No usable Mojo', 1 if !eval { require Mojo::IOLoop };

        require Mojolicious;

        skip "Mojo is $Mojolicious::VERSION; needs >= 8.15", 1 if !eval { Mojolicious->VERSION('8.15') };

        diag "Testing Mojo ($Mojolicious::VERSION) …";

        require Protocol::DBus::Client::Mojo;

        my $ok = eval {
            my $dbus = Protocol::DBus::Client::Mojo::login_session();

            $dbus->initialize()->wait();

            1;
        };

        my $err = $@;

        ok( $ok, 'Mojo can initialize()' ) or diag explain $err;
    }
}

done_testing();
