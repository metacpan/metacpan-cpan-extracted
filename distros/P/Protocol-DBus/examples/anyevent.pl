#!/usr/bin/perl

#----------------------------------------
# Contributed by Erik Huelsmann (ehuels@gmail.com)
#----------------------------------------

use strict;
use warnings;

use AnyEvent;
use Data::Dumper;
use Protocol::DBus;
use Protocol::DBus::Client;

my $dbus = $> ? Protocol::DBus::Client::login_session() : Protocol::DBus::Client::system();
$dbus->blocking(0);

my $authenticated = AnyEvent->condvar;
my $w;
$w = AnyEvent->io(fh => $dbus->fileno(), poll => 'rw',
      cb => sub {
         if ($dbus->initialize()) {
            $authenticated->send();
            undef $w;
         }
     });

$authenticated->recv;

my $waiter = AnyEvent->condvar;

$w = AnyEvent->io(fh => $dbus->fileno(), poll => 'r',
      cb => sub {
         my $msg = $dbus->get_message;
         $waiter->send($msg);
     });


print Dumper $waiter->recv;
$waiter = AnyEvent->condvar;

$dbus->send_call(
    member => 'CreateTransaction',
    path => '/org/freedesktop/PackageKit',
    destination => 'org.freedesktop.PackageKit',
    interface => 'org.freedesktop.PackageKit',
);

my $trans_path = shift @{$waiter->recv->get_body};
$waiter = AnyEvent->condvar;


$w = AnyEvent->io(fh => $dbus->fileno(), poll => 'r',
      cb => sub {
         my $msg = $dbus->get_message();
         print Dumper $msg->get_body();

         if ($msg->get_header('MEMBER') eq 'Finished') {
           $waiter->send;
         }
     });


$dbus->send_call(
    member => 'AddMatch',
    signature => 's',
    destination => 'org.freedesktop.DBus',
    interface => 'org.freedesktop.DBus',
    path => '/org/freedesktop/DBus',
    body => [
       "path='$trans_path'"
    ]
);

$dbus->send_call(
    member => 'GetPackages',
    signature => 't',
    path => $trans_path,
    destination => 'org.freedesktop.PackageKit',
    interface => 'org.freedesktop.PackageKit.Transaction',
    body => [ 4 ],
);

$waiter->recv;
