# -*- perl -*-
use Test::More tests => 3;

use strict;
use warnings;

BEGIN { 
    use_ok('Net::DBus::Binding::Introspector');
    use_ok('Net::DBus::Object');
};

my $bus = Net::DBus->test;
my $service = $bus->export_service("/org/cpan/Net/DBus/Test/introspect");

my $object = Net::DBus::Object->new($service, "/org/example/Object/OtherObject");

my $introspector = $object->_introspector;

my $xml_got = $introspector->format($object);
    
my $xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/org/example/Object/OtherObject">
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

