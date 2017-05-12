#!/usr/bin/perl

use Net::DBus::GLib;
use Net::DBus::Service;

#...  continued at bottom


package SomeObject;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(org.designfu.SampleInterface);

sub new {
    my $class = shift;
    my $service = shift;
    my $self = $class->SUPER::new($service, "/SomeObject");
    bless $self, $class;
    
    return $self;
}

dbus_method("HelloWorld", ["string"], [["array", "string"]]);
sub HelloWorld {
    my $self = shift;
    my $message = shift;
    print "Do hello world\n";
    print $message, "\n";
    return ["Hello", " from example-service.pl"];
}

dbus_method("GetDict", [], [["dict", "string", "string"]]);
sub GetDict {
    my $self = shift;
    print "Do get dict\n";
    return {"first" => "Hello Dict", "second" => " from example-service.pl"};
}

dbus_method("GetTuple", [], [["struct", "string", "string"]]);
sub GetTuple {
    my $self = shift;
    print "Do get tuple\n";
    return ["Hello Tuple", " from example-service.pl"];
}

package main;

my $bus = Net::DBus::GLib->session();
my $service = $bus->export_service("org.designfu.SampleService");
my $object = SomeObject->new($service);

Glib::MainLoop->new()->run();

