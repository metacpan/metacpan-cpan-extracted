#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::Object );

use PingCommon qw( SERVICE_NAME );

sub main {
    my $app = Qt::Application(\@ARGV);

    if (!Qt::DBusConnection::sessionBus()->isConnected()) {
        die "Cannot connect to the D-BUS session bus.\n" .
                "To start it, run:\n" .
                "\teval `dbus-launch --auto-syntax`\n";
    }

    my $iface = Qt::DBusInterface(SERVICE_NAME, '/', '', Qt::DBusConnection::sessionBus());
    if ($iface->isValid()) {
        my $reply = Qt::DBusReply( $iface->call( 'ping', Qt::Variant(@ARGV > 0 ? Qt::String($ARGV[0]) : Qt::String(''))) );
        if ($reply->isValid()) {
            printf "Reply was: %s\n", $reply->value();
            exit 0;
        }

        printf STDERR "Call failed: %s\n", $reply->error()->message();
        exit 1;
    }

    printf STDERR "%s\n",
            Qt::DBusConnection::sessionBus()->lastError()->message();
    exit 1;
}

main();
