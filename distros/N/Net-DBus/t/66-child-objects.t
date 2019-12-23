# -*- perl -*-
use Test::More tests => 5;

use strict;
use warnings;

BEGIN { 
    use_ok('Net::DBus::Binding::Introspector');
    use_ok('Net::DBus::Object');
};

package ObjectType1;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(com.dbelser.test.type1);

sub new {
  my $class = shift;
  my $service = shift;
  my $path = shift;
  my $name = shift;

  my $self = $class->SUPER::new($service, "$path");
  bless $self, $class;

  $self->{name} = $name;
  return $self;
}

dbus_method("version", [], ["string"], { arg_names=>["version"],} );
sub version {
  my $self = shift;
  return ("$self->{name}: ObjectType1, Version 0.1");
}


package ObjectType2;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(com.dbelser.test.type2);

sub new {
  my $class = shift;
  my $service = shift;
  my $path = shift;
  my $name = shift;

  my $self = $class->SUPER::new($service, "$path");
  bless $self, $class;
  $self->{name} = $name;

  return $self;
}

dbus_method("version", [], ["string"], { arg_names=>["version"],} );
sub version {
  my $self = shift;
  return ("$self->{name}: ObjectType2, Version 0.1");
}


package ObjectType3;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(com.dbelser.test.type3);

sub new {
  my $class = shift;
  my $service = shift;
  my $path = shift;
  my $name = shift;

  my $self = $class->SUPER::new($service, "$path");
  bless $self, $class;
  $self->{name} = $name;

  return $self;
}

dbus_method("version", [], ["string"], { arg_names=>["version"],} );
sub version {
  my $self = shift;
  return ("$self->{name}: ObjectType3, Version 0.1");
}


package main;

use Net::DBus qw(:typing);
my $bus = Net::DBus->test;
my $service = $bus->export_service("org.cpan.Net.Bus.test");

# base path for this app
my $base = "/base";

my $root = ObjectType1->new($service,$base,"Root");

# second tier one each
my $c1   = ObjectType1->new($root,"/branch_1", "C1");
my $c2   = ObjectType2->new($root,"/branch_2", "C2");
my $c3   = ObjectType3->new($root,"/branch_3", "C3");

# go deep
my $c4   = ObjectType1->new($c1,"/one", "C4");
my $c5   = ObjectType2->new($c4,"/two", "C5");
my $c6   = ObjectType3->new($c5,"/three", "C6");

# skip some nodes
my $c7   = ObjectType1->new($c2,"/skip/one", "C7");
my $c8   = ObjectType2->new($c7,"/skip/skip/two", "C8");
my $c9   = ObjectType3->new($c8,"/skip/skip/skip/three", "C9");

my $introspector = $root->_introspector;
my $xml_got = $introspector->format($root);

my $xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/base">
  <interface name="com.dbelser.test.type1">
    <method name="version">
      <arg type="s" direction="out"/>
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
  <node name="branch_1"/>
  <node name="branch_2"/>
  <node name="branch_3"/>
</node>
EOF

is($xml_got, $xml_expect, "xml data matches");

my $ins2 = Net::DBus::Binding::Introspector->new(xml => $xml_got);

my @children = $ins2->list_children();
is_deeply(\@children, ["branch_1", "branch_2", "branch_3"], "children match");


$introspector = $c2->_introspector;
$xml_got = $introspector->format($c2);

$xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/base/branch_2">
  <interface name="com.dbelser.test.type2">
    <method name="version">
      <arg type="s" direction="out"/>
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
  <node name="skip"/>
</node>
EOF
is($xml_got, $xml_expect, "xml data matches");
