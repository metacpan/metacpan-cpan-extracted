#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

SKIP: {
    skip 'No AnyEvent!', 1 if !eval { require AnyEvent };

    require Protocol::DBus::Client::AnyEvent;

    my $dbus = eval {
        Protocol::DBus::Client::AnyEvent::login_session();
    } or skip "Can’t open login session: $@";

    my $cv = AnyEvent->condvar();

    my $timer = AnyEvent->timer(
        after => 0.1,
        cb => $cv,
    );

    $dbus->initialize()->then(
        sub {
            my $msgr = shift;

            # NOT to be done in production. This can change at any time.
            my $dbus = $msgr->_dbus();

            my $fileno = $dbus->fileno();
            open my $fh, "+>&=$fileno" or die "failed to take fd $fileno: $!";

            syswrite $fh, 'z';

            $msgr->send_signal(
                path => '/what/ever',
                interface => 'what.ever',
                member => 'member',
            )->then(
                sub { diag "signal sent\n" },
                sub { diag "signal NOT sent\n" },
            );
        },
        sub {
            $cv->();
            skip "Failed to initialize: $_[0]", 1;
        },
    );

    my @w;
    do {
        local $SIG{'__WARN__'} = sub { push @w, @_; };
        $cv->recv();
    };

    is(
        0 + @w,
        1,
        'single warning',
    ) or diag explain \@w;
};

done_testing;

1;
