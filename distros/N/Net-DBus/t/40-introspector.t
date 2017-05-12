# -*- perl -*-
use Test::More tests => 6;

use strict;
use warnings;

BEGIN { 
        use_ok('Net::DBus::Binding::Introspector');
	};


TEST_ONE: {
    my $other_object = Net::DBus::Binding::Introspector->new(
						    object_path => "org.example.Object.OtherObject",
						    interfaces => {
							"org.example.SomeInterface" => {
							    methods => {
								"hello" => {
								    params => ["int32", "int32", ["struct", "int32","byte"]],
								    returns => ["int32"],
								    paramnames => ["wibble", "eek"],
								    returnnames => ["frob"],
								},
								"goodbye" => {
								    params => [["array", ["struct", "int32", "string"]]],
								    returns => ["string", "string"],
								    paramnames => ["ooh"],
								    returnnames => ["ahh", "eek"],
								},
								"nested" => {
								    params => [["dict", "string", ["array", ["array", "string"]]]],
								    returns => [],
								},
							    },
							    signals => {
								"meltdown" => {
								    params => ["int32", "byte"],
								}
							    },
							    props => {
								"name" => { type => "string", access => "readwrite"},
								"email" => { type => "string", access => "read"},
								"age" => { type => "int32", access => "read"},
								"parents" => { type => ["array", "string"], access => "readwrite" },
							    },
							}
						    });

    isa_ok($other_object, "Net::DBus::Binding::Introspector");
    
    my $other_xml_got = $other_object->format();
    
    my $other_xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="org.example.Object.OtherObject">
  <interface name="org.example.SomeInterface">
    <method name="goodbye">
      <arg name="ooh" type="a(is)" direction="in"/>
      <arg name="ahh" type="s" direction="out"/>
      <arg name="eek" type="s" direction="out"/>
    </method>
    <method name="hello">
      <arg name="wibble" type="i" direction="in"/>
      <arg name="eek" type="i" direction="in"/>
      <arg type="(iy)" direction="in"/>
      <arg name="frob" type="i" direction="out"/>
    </method>
    <method name="nested">
      <arg type="a{saas}" direction="in"/>
    </method>
    <signal name="meltdown">
      <arg type="i"/>
      <arg type="y"/>
    </signal>
    <property name="age" type="i" access="read"/>
    <property name="email" type="s" access="read"/>
    <property name="name" type="s" access="readwrite"/>
    <property name="parents" type="as" access="readwrite"/>
  </interface>
</node>
EOF
    is($other_xml_got, $other_xml_expect, "xml data matches");

    my $object = Net::DBus::Binding::Introspector->new(
					      object_path => "org.example.Object",
					      interfaces => {
						  "org.example.SomeInterface" => {
						      methods => {
							  "hello" => {
							      params => ["int32", "int32", ["struct", "int32","byte"]],
							      returns => ["uint32"],
							      paramnames => [],
							      returnnames => [],
							  },
							  "goodbye" => {
							      params => [["array", ["dict", "int32", "string"]]],
							      returns => ["string", ["array", "string"]],
							      paramnames => [],
							      returnnames => [],
							  },
						      },
						      signals => {
							  "meltdown" => {
							      params => ["int32", "byte"],
							      paramnames => [],
							  }
						      },
						  },
						  "org.example.OtherInterface" => {
						      methods => {
							  "hitme" => {
							      params => ["int32", "uint32"],
							      return => [],
							      paramnames => [],
							      returnnames => [],
							  }
						      },
						      props => {
							  "title" => { type => "string", access => "readwrite"},
							  "salary" => { type => "int32", access => "read"},
						      },
						 },
					      },
					      children => [
							   "org.example.Object.SubObject",
							   $other_object,
							   ]);
    
    isa_ok($object, "Net::DBus::Binding::Introspector");

    my $object_xml_got = $object->format();
    
    my $object_xml_expect = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="org.example.Object">
  <interface name="org.example.OtherInterface">
    <method name="hitme">
      <arg type="i" direction="in"/>
      <arg type="u" direction="in"/>
    </method>
    <property name="salary" type="i" access="read"/>
    <property name="title" type="s" access="readwrite"/>
  </interface>
  <interface name="org.example.SomeInterface">
    <method name="goodbye">
      <arg type="aa{is}" direction="in"/>
      <arg type="s" direction="out"/>
      <arg type="as" direction="out"/>
    </method>
    <method name="hello">
      <arg type="i" direction="in"/>
      <arg type="i" direction="in"/>
      <arg type="(iy)" direction="in"/>
      <arg type="u" direction="out"/>
    </method>
    <signal name="meltdown">
      <arg type="i"/>
      <arg type="y"/>
    </signal>
  </interface>
  <node name="org.example.Object.SubObject"/>
  <node name="org.example.Object.OtherObject">
    <interface name="org.example.SomeInterface">
      <method name="goodbye">
        <arg name="ooh" type="a(is)" direction="in"/>
        <arg name="ahh" type="s" direction="out"/>
        <arg name="eek" type="s" direction="out"/>
      </method>
      <method name="hello">
        <arg name="wibble" type="i" direction="in"/>
        <arg name="eek" type="i" direction="in"/>
        <arg type="(iy)" direction="in"/>
        <arg name="frob" type="i" direction="out"/>
      </method>
      <method name="nested">
        <arg type="a{saas}" direction="in"/>
      </method>
      <signal name="meltdown">
        <arg type="i"/>
        <arg type="y"/>
      </signal>
      <property name="age" type="i" access="read"/>
      <property name="email" type="s" access="read"/>
      <property name="name" type="s" access="readwrite"/>
      <property name="parents" type="as" access="readwrite"/>
    </interface>
  </node>
</node>
EOF
    is($object_xml_got, $object_xml_expect, "xml data matches");
    
    
    my $recon_other = Net::DBus::Binding::Introspector->new(xml => $object_xml_got);
    
    my $object_xml_got_again = $recon_other->format();
    
    is($object_xml_got_again, $object_xml_expect, "reconstructed xml matches");
}
