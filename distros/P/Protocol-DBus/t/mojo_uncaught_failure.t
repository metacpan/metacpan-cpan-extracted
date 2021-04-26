#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBusSession;

SKIP: {
    skip 'No Mojo::IOLoop!', 1 if !eval { require Mojo::IOLoop };
    skip 'No Mojo::Promise!', 1 if !eval { require Mojo::Promise };
    skip 'Loop can’t timer()!', 1 if !Mojo::IOLoop->can('timer');

    require Mojolicious;

    skip "Mojo is $Mojolicious::VERSION; needs >= 8.15", 1 if !eval { Mojolicious->VERSION('8.15') };

    DBusSession::skip_if_lack_needed_socket_msghdr(1);

    DBusSession::get_bin_or_skip();

    my $session = DBusSession->new();

    require Protocol::DBus::Client::Mojo;

    my $dbus = eval {
        Protocol::DBus::Client::Mojo::login_session();
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
                sub { diag "signal NOT sent (@_)\n" },
            );
        },
        sub {
            skip "Failed to initialize: $_[0]", 1;
        },
    );

    my ($warn_y);
    my $warn_p = Mojo::Promise->new( sub {
        $warn_y = shift;
    } );

    my @w;
    do {
        local $SIG{'__WARN__'} = sub {
            $warn_y->();
            push @w, @_;
        };

        Mojo::Promise->all($warn_p, $dbus_p)->wait();
    };

    is(
        0 + @w,
        1,
        'single warning',
    ) or diag explain \@w;
};

done_testing;

1;
