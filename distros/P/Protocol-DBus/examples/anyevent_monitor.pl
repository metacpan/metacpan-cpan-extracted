#!/usr/bin/env perl

use strict;
use warnings;

use experimental 'signatures';

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../../p5-Promise-ES6/lib";
use lib "$FindBin::Bin/../lib";

use AnyEvent;

use Protocol::DBus::Client::AnyEvent;

use JSON;

my $json = JSON->new()->allow_nonref();

{
    my $dbus = Protocol::DBus::Client::AnyEvent::login_session();

    my %type_name = reverse %{ Protocol::DBus::Message::Header::MESSAGE_TYPE() };

    $dbus->on_signal( sub ($msg) {
        my $type = $type_name{ $msg->get_type() };

        printf "%s from %s$/", $type, $msg->get_header('SENDER');

        printf "\tType: %s.%s$/", map { $msg->get_header($_) } qw( INTERFACE MEMBER );

        printf "\tBody: (%s) %s$/", $msg->get_header('SIGNATURE'), $json->encode($msg->get_body());
        print $/;
    } );

    $dbus->initialize()->then( sub ($msgr) {
        $msgr->send_call(
            path        => '/org/freedesktop/DBus',
            interface   => 'org.freedesktop.DBus',
            member      => 'AddMatch',
            destination => 'org.freedesktop.DBus',
            signature   => 's',
            body        => [ q<> ],
        );
    } );

    AnyEvent->condvar()->recv();
}

1;
