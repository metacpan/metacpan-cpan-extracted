#!/usr/bin/perl

package NetworkBroadcastTest;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use Sender;
use lib '../broadcastreceiver';
use Receiver;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [],
    getBroadcast =>[];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub getBroadcast {
    my $sender = this->{sender};
    my $receiver = this->{receiver};

    my $spy = Qt::SignalSpy( $sender->timer, SIGNAL 'timeout()' );

    Qt::Test::keyClick(
        $sender->startButton(),
        Qt::Key_Enter(),
    );

    Qt::Test::qWait(3500);

    is( scalar @{$spy}, 3, 'Send/Receive datagram count' );

    is( $receiver->statusLabel()->text(),
        'Received datagram: "Broadcast message 3"',
        'Send/Receive datagram' );
}

sub initTestCase {
    my $sender = Sender();
    $sender->show();
    Qt::Test::qWaitForWindowShown( $sender );
    this->{sender} = $sender;

    my $receiver = Receiver();
    $receiver->show();
    Qt::Test::qWaitForWindowShown( $receiver );
    this->{receiver} = $receiver;

    pass( 'Window shown' );
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use NetworkBroadcastTest;
use Test::More tests => 3;

exit QTEST_MAIN('NetworkBroadcastTest');
