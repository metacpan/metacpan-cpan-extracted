# -*- perl -*-
use Test::More tests => 13;

use strict;
use warnings;

BEGIN {
    use_ok('Net::DBus::Binding::Introspector');
    use_ok('Net::DBus::Object');
};

package MyObject;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(org.example.MyObject);

dbus_method("test_set_serial", ["serial"]);
sub test_set_serial {
    my $self = shift;
    my @args = @_;
    $self->{lastargs} = \@args;
}

dbus_method("test_set_caller", ["caller"]);
sub test_set_caller {
    my $self = shift;
    my @args = @_;
    $self->{lastargs} = \@args;
}

dbus_method("test_set_multi_args1", ["string", "caller"]);
sub test_set_multi_args1 {
    my $self = shift;
    my @args = @_;
    $self->{lastargs} = \@args;
}

dbus_method("test_set_multi_args2", ["caller", "string"]);
sub test_set_multi_args2 {
    my $self = shift;
    my @args = @_;
    $self->{lastargs} = \@args;
}

dbus_method("test_set_multi_args3", ["string", "caller", "string"]);
sub test_set_multi_args3 {
    my $self = shift;
    my @args = @_;
    $self->{lastargs} = \@args;
}

package main;

my $bus = Net::DBus->test;
my $service = $bus->export_service("/org/cpan/Net/Bus/test");
my $object = MyObject->new($service, "/org/example/MyObject");

my $introspector = $object->_introspector;

my $xml_got = $introspector->format($object);

my $xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/org/example/MyObject">
  <interface name="org.example.MyObject">
    <method name="test_set_caller">
    </method>
    <method name="test_set_multi_args1">
      <arg type="s" direction="in"/>
    </method>
    <method name="test_set_multi_args2">
      <arg type="s" direction="in"/>
    </method>
    <method name="test_set_multi_args3">
      <arg type="s" direction="in"/>
      <arg type="s" direction="in"/>
    </method>
    <method name="test_set_serial">
    </method>
  </interface>
  <interface name="org.freedesktop.DBus.Introspectable">
    <method name="Introspect">
      <arg name="xml_data" type="s" direction="out"/>
    </method>
  </interface>
  <interface name="org.freedesktop.DBus.Properties">
    <method name="Get">
      <arg name="interface_name" type="s" direction="in"/>
      <arg name="property_name" type="s" direction="in"/>
      <arg name="value" type="v" direction="out"/>
    </method>
    <method name="GetAll">
      <arg name="interface_name" type="s" direction="in"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
    <method name="Set">
      <arg name="interface_name" type="s" direction="in"/>
      <arg name="property_name" type="s" direction="in"/>
      <arg name="value" type="v" direction="in"/>
    </method>
  </interface>
</node>
EOF

is($xml_got, $xml_expect, "xml data matches");

CALLER: {
    my $msg = Net::DBus::Binding::Message::MethodCall->new(service_name => "org.example.MyService",
							   object_path => "/org/example/MyObject",
							   interface => "org.example.MyObject",
							   method_name => "test_set_caller");
    $msg->set_sender(":1.1");

    my $reply = $bus->get_connection->send_with_reply_and_block($msg);
    is($reply->get_type, &Net::DBus::Binding::Message::MESSAGE_TYPE_METHOD_RETURN);

    is_deeply($object->{lastargs}, [":1.1"], "caller is :1.1");
}


SERIAL: {
    my $msg = Net::DBus::Binding::Message::MethodCall->new(service_name => "org.example.MyService",
							   object_path => "/org/example/MyObject",
							   interface => "org.example.MyObject",
							   method_name => "test_set_serial");

    my $reply = $bus->get_connection->send_with_reply_and_block($msg);

    is($reply->get_type, &Net::DBus::Binding::Message::MESSAGE_TYPE_METHOD_RETURN);

    is_deeply($object->{lastargs}, [$msg->get_serial], "serial matches");
}

MULTI_ARGS1: {
    my $msg = Net::DBus::Binding::Message::MethodCall->new(service_name => "org.example.MyService",
							   object_path => "/org/example/MyObject",
							   interface => "org.example.MyObject",
							   method_name => "test_set_multi_args1");
    $msg->set_sender(":1.1");
    my $iter = $msg->iterator(1);
    $iter->append_string("one");

    my $reply = $bus->get_connection->send_with_reply_and_block($msg);

    is($reply->get_type, &Net::DBus::Binding::Message::MESSAGE_TYPE_METHOD_RETURN);

    is_deeply($object->{lastargs}, ["one",":1.1"], "caller matches");
}

MULTI_ARGS2: {
    my $msg = Net::DBus::Binding::Message::MethodCall->new(service_name => "org.example.MyService",
							   object_path => "/org/example/MyObject",
							   interface => "org.example.MyObject",
							   method_name => "test_set_multi_args2");
    $msg->set_sender(":1.1");
    my $iter = $msg->iterator(1);
    $iter->append_string("one");

    my $reply = $bus->get_connection->send_with_reply_and_block($msg);

    is($reply->get_type, &Net::DBus::Binding::Message::MESSAGE_TYPE_METHOD_RETURN);

    is_deeply($object->{lastargs}, [":1.1", "one"], "caller matches");
}

MULTI_ARGS3: {
    my $msg = Net::DBus::Binding::Message::MethodCall->new(service_name => "org.example.MyService",
							   object_path => "/org/example/MyObject",
							   interface => "org.example.MyObject",
							   method_name => "test_set_multi_args3");
    $msg->set_sender(":1.1");
    my $iter = $msg->iterator(1);
    $iter->append_string("one");
    $iter->append_string("two");

    my $reply = $bus->get_connection->send_with_reply_and_block($msg);

    is($reply->get_type, &Net::DBus::Binding::Message::MESSAGE_TYPE_METHOD_RETURN);

    is_deeply($object->{lastargs}, ["one",":1.1", "two"], "caller matches");
}
