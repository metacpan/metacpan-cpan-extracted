#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBusSession;

SKIP: {
    skip 'No IO::Async!', 1 if !eval { require IO::Async::Loop };

    my $loop = IO::Async::Loop->new();
    skip 'Loop can’t watch_time()!', 1 if !$loop->can('watch_time');

    DBusSession::skip_if_lack_needed_socket_msghdr(1);

    DBusSession::get_bin_or_skip();

    my $session = DBusSession->new();

    require Protocol::DBus::Client::IOAsync;

    my $dbus = eval {
        Protocol::DBus::Client::IOAsync::login_session($loop);
    } or skip "Can’t open login session: $@";

    my $dbus_p = $dbus->initialize()->then(
        sub {
            my $msgr = shift;

            # NOT to be done in production. This can change at any time.
            my $dbus = $msgr->_dbus();

            my $fileno = $dbus->fileno();
            open my $fh, "+>&=$fileno" or die "failed to take fd $fileno: $!";

            syswrite $fh, 'z';

            return $msgr->send_signal(
                path => '/what/ever',
                interface => 'what.ever',
                member => 'member',
            )->then(
                sub { diag "signal sent\n" },
                sub { diag "signal NOT sent\n" },
            );
        },
        sub {
            skip "Failed to initialize: $_[0]", 1;
        },
    );

    my $warn_y;
    my $warn_p = Promise::ES6->new( sub {
        $warn_y = shift;
    } );

    my @w;
    do {
        local $SIG{'__WARN__'} = sub {
            $warn_y->();
            push @w, @_;
        };

        Promise::ES6->all([$dbus_p, $warn_p])->then( sub {
            $loop->stop();
        } );

        $loop->run();
    };

    is(
        0 + @w,
        1,
        'single warning',
    ) or diag explain \@w;
};

done_testing;

1;
