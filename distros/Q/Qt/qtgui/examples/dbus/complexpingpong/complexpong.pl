#!/usr/bin/perl

package Pong;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::DBusAbstractAdaptor );
use QtCore4::classinfo
    'D-Bus Interface' => 'com.trolltech.QtDBus.ComplexPong.Pong';

use QtCore4::signals
    aboutToQuit => [];
use QtCore4::slots
    'QDBusVariant query' => ['const QString&'],
    'QString value' => [],
    setValue => ['QString'],
    quit => [];

sub NEW {
    shift->SUPER::NEW( @_ );
}

# the property
sub value() {
    return this->{m_value};
}

sub setValue {
    my ($newValue) = @_;
    this->{m_value} = $newValue;
}

sub quit {
    Qt::Timer::singleShot(0, Qt::Application::instance(), SLOT 'quit()');
}

sub query {
    my ( $query ) = @_;
    my $q = lc $query;
    if ($q eq 'hello') {
        return Qt::DBusVariant(Qt::String('World'));
    }
    if ($q eq 'ping') {
        return Qt::DBusVariant(Qt::String('Pong'));
    }
    if ($q =~ m/the answer to life, the universe and everything/) {
        return Qt::DBusVariant(Qt::Int(42));
    }
    if ($q =~ m/unladen swallow/) {
        if ($q =~ m/european/) {
            return Qt::DBusVariant(Qt::Int(11.0));
        }
        return Qt::DBusVariant(Qt::String('african or european?'));
    }

    return Qt::DBusVariant(Qt::String('Sorry, I don\'t know the answer'));
}

1;

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtDBus4;
use PingCommon qw( SERVICE_NAME );
use Pong;

sub main {
    my $app = Qt::Application( \@ARGV );

    my $obj = Qt::Object();
    my $pong = Pong($obj);
    $pong->connect($app, SIGNAL 'aboutToQuit()', SIGNAL 'aboutToQuit()' );
    $pong->setValue(Qt::Variant(Qt::String('initial value')));
    Qt::DBusConnection::sessionBus()->registerObject('/', $obj);

    if (!Qt::DBusConnection::sessionBus()->registerService(SERVICE_NAME)) {
        printf STDERR "%s\n",
                Qt::DBusConnection::sessionBus()->lastError()->message();
        exit 1;
    }
    
    exit $app->exec();
}

main();
