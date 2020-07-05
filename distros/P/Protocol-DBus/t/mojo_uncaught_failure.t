#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

SKIP: {
    skip 'No Mojo::IOLoop!', 1 if !eval { require Mojo::IOLoop };
    skip 'Loop can’t timer()!', 1 if !Mojo::IOLoop->can('timer');

    require Protocol::DBus::Client::Mojo;

    my $dbus = eval {
        Protocol::DBus::Client::Mojo::login_session();
    } or skip "Can’t open login session: $@";

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
            )->finally( sub {
                Mojo::IOLoop->timer( 0.1 => sub { Mojo::IOLoop->stop } );
            } );
        },
        sub {
            Mojo::IOLoop->stop;
            skip "Failed to initialize: $_[0]", 1;
        },
    );

    my @w;
    do {
        local $SIG{'__WARN__'} = sub { push @w, @_; };
        Mojo::IOLoop->start();
    };

    is(
        0 + @w,
        1,
        'single warning',
    ) or diag explain \@w;
};

done_testing;

1;
