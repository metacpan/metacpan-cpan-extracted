#!/usr/bin/perl

package Ping;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::Object );
use QtCore4::slots
    start => ['const QString&', 'const QString&', 'const QString&'];
use PingCommon qw( SERVICE_NAME );

sub NEW {
    shift->SUPER::NEW( @_ );
}

sub iface() {
    return this->{iface};
}

my $foo = 0;

sub start {
    my ($name, $oldValue, $newValue) = @_;

    if ($name ne SERVICE_NAME || !$newValue) {
        return;
    }

    # find our remote
    this->{iface} = Qt::DBusInterface(SERVICE_NAME, '/', 'com.trolltech.QtDBus.ComplexPong.Pong',
                               Qt::DBusConnection::sessionBus(), this);
    if (!this->iface->isValid()) {
        printf STDERR "%s\n",
                Qt::DBusConnection::sessionBus()->lastError()->message();
        Qt::Application::instance()->quit();
    }

    this->connect(this->iface, SIGNAL 'aboutToQuit()', Qt::Application::instance(), SLOT 'quit()');

    while (1) {
        printf 'Ask your question: ';

        chop( my $line = <STDIN> );
        if (!$line) {
            this->iface->call('quit');
            return;
        } elsif ($line eq 'value') {
            my $reply = Qt::Variant( this->iface->value() );
            if ($reply) {
                printf "value = %s\n", $reply->toString();
            }
        } elsif ($line =~ m/^value=/) {
            my $property = $line =~ s/^value=//;
            this->iface->setValue( Qt::Variant($property) );
        } else {
            my $reply = Qt::DBusReply( this->iface->call( 'query', Qt::Variant(Qt::String($line))) );
            if ($reply->isValid()) {
                printf "Reply was: %s\n", $reply->value()->value();
            }
        }

        if (this->iface->lastError()->isValid()) {
            printf STDERR "Call failed: %s\n", this->iface->lastError()->message();
        }
    }
}

1;

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtDBus4;
use Ping;

sub main {
    my $app = Qt::Application(\@ARGV);

    if (!Qt::DBusConnection::sessionBus()->isConnected()) {
        printf STDERR "Cannot connect to the D-Bus session bus.\n" .
                "To start it, run:\n" .
                "\teval `dbus-launch --auto-syntax`\n";
        exit 1;
    }

    my $ping = Ping();
    $ping->connect(Qt::DBusConnection::sessionBus()->interface(),
                 SIGNAL 'serviceOwnerChanged(QString,QString,QString)',
                 SLOT 'start(QString,QString,QString)');

    my $pong = Qt::Process();
    $pong->start('./complexpong.pl');

    exit $app->exec();
}

main();
