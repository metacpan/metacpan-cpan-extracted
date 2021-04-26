#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use DBusSession;

SKIP: {
    skip 'No AnyEvent!', 1 if !eval { require AnyEvent::Loop };

    DBusSession::skip_if_lack_needed_socket_msghdr(1);

    DBusSession::get_bin_or_skip();

    my $session = DBusSession->new();

    require Protocol::DBus::Client::AnyEvent;

    my $dbus = eval {
        Protocol::DBus::Client::AnyEvent::login_session();
    } or skip "Can’t open login session: $@";

    my $cv = AnyEvent->condvar();

    my $on_signal_cr;
    $dbus->on_signal(
        sub {
            $on_signal_cr->(shift) if $on_signal_cr;
        },
    );

    my @received_after_resume;

    my $bus_name;

    $dbus->initialize()->then(
        sub {
            my $messenger = shift;

            $bus_name = $messenger->get_unique_bus_name();

            return Promise::ES6->new( sub {
                my ($y, $n) = @_;

                my $timer = AnyEvent->timer(
                    after => 5,
                    cb => sub {
                        $n->('timed out');
                    },
                );

                $on_signal_cr = sub {
                    my ($msg) = @_;

                    if ($msg->get_header('PATH') eq '/test/pdb') {
                        diag 'Got sanity-check signal';
                        undef $timer;
                        $y->($messenger);
                    }
                };

                $messenger->send_signal(
                    path => '/test/pdb',
                    interface => 'test.pdb',
                    member => 'message',
                    destination => $bus_name,   # myself
                )->then(
                    sub {
                        diag 'sent sanity-check signal';
                    },
                );
            } );
        },
    )->then(
        sub {
            my $messenger = shift;

            my @received_while_paused;

            $on_signal_cr = sub {
                diag 'oops! received a message while paused!';
                push @received_while_paused, shift;
            };

            $messenger->pause();
            diag 'paused';

            $messenger->send_signal(
                path => '/test/pdb',
                interface => 'test.pdb',
                member => 'message',
                destination => $bus_name,   # myself
                signature => 's',
                body => ['real message'],
            )->then( sub {
                diag 'sent “real” test message';
            } );

            return Promise::ES6->new( sub {
                my ($y, $n) = @_;

                my $timer;
                $timer = AnyEvent->timer(
                    after => 1,
                    cb => sub {
                        undef $timer;

                        is(
                            "@received_while_paused",
                            q<>,
                            'got nothing while paused',
                        ) or diag explain \@received_while_paused;

                        $y->($messenger);
                    },
                );

                diag 'Waiting to see if pause() works …';
            } );
        },
    )->then(
        sub {
            my $messenger = shift;

            return Promise::ES6->new( sub {
                my ($y, $n) = @_;

                my $timer;

                $on_signal_cr = sub {
                    undef $timer;
                    push @received_after_resume, shift;
                    $y->();
                };

                diag 'resuming';
                $messenger->resume();
                diag 'resumed';

                $timer = AnyEvent->timer(
                    after => 10,
                    cb => sub {
                        undef $timer;
                        $n->('timeout waiting for D-Bus signal!');
                    },
                );
            } );
        },
    )->finally($cv);

    $cv->recv();

    cmp_deeply(
        \@received_after_resume,
        [ Isa('Protocol::DBus::Message') ],
        'received signal after resume',
    );
}

done_testing;

1;
