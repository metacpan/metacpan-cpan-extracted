#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

SKIP: {
    skip 'No IO::Async!', 1 if !eval { require IO::Async::Loop };

    my $loop = IO::Async::Loop->new();
    skip 'Loop can’t watch_time()!', 1 if !$loop->can('watch_time');

    require Protocol::DBus::Client::IOAsync;

    my $dbus = eval {
        Protocol::DBus::Client::IOAsync::login_session($loop);
    } or skip "Can’t open login session: $@";

    $loop->watch_time( after => 0.1, code => sub { $loop->stop } );

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
            $loop->stop;
            skip "Failed to initialize: $_[0]", 1;
        },
    );

    my @w;
    do {
        local $SIG{'__WARN__'} = sub { push @w, @_; };
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
