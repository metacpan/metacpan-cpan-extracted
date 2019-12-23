# -*- perl -*-

use Test::More tests => 94;

use strict;
use warnings;

package MyObject1;

use strict;
use warnings;
use Test::More;
use base qw(Net::DBus::Object);
use Net::DBus;
use Net::DBus::Service;

use Net::DBus::Exporter qw(org.example.MyObject);

my $bus = Net::DBus->test;
my $service = $bus->export_service("org.example.MyService");
my $obj = MyObject1->new($service, "/org/example/MyObject");

# First the full APIs
dbus_method("Everything", ["string"], ["int32"]);
dbus_method("EverythingInterface", ["string"], ["int32"], "org.example.OtherObject");

# Now add in annotations to the mix
dbus_method("EverythingAnnotate", ["string"], ["int32"], { deprecated => 1, 
							   no_return => 1 });
dbus_method("EverythingNegativeAnnotate", ["string"], ["int32"], { deprecated => 0, 
								   no_return => 0 });
dbus_method("EverythingInterfaceAnnotate", ["string"], ["int32"], "org.example.OtherObject", { deprecated => 1, 
											       no_return => 1 });
dbus_method("EverythingInterfaceNegativeAnnotate", ["string"], ["int32"], "org.example.OtherObject", { deprecated => 0, 
												       no_return => 0 });

# Now test 'defaults'
dbus_method("NoArgsReturns");
dbus_method("NoReturns", ["string"], [], { param_names => ["wizz"] });
dbus_method("NoArgs",[],["int32"]);
dbus_method("NoArgsReturnsInterface", "org.example.OtherObject");
dbus_method("NoReturnsInterface", ["string"], "org.example.OtherObject");
dbus_method("NoArgsInterface", [],["int32"], "org.example.OtherObject");

dbus_method("NoArgsReturnsAnnotate", { deprecated => 1 });
dbus_method("NoReturnsAnnotate", ["string"], { deprecated => 1 });
dbus_method("NoArgsAnnotate",[],["int32"], { deprecated => 1 });
dbus_method("NoArgsReturnsInterfaceAnnotate", "org.example.OtherObject", { deprecated => 1 });
dbus_method("NoReturnsInterfaceAnnotate", ["string"], "org.example.OtherObject", { deprecated => 1, param_names => ["one"] });
dbus_method("NoArgsInterfaceAnnotate", [],["int32"], "org.example.OtherObject", { deprecated => 1, return_names => ["two"] });

dbus_method("DemoInterfaceName1", [], ["string"], "_org.example._some_9object");

eval {
    dbus_method("DemoInterfaceName2", [], ["string"], "9org.example.SomeObject");
};
ok($@ ne "", "raised error for leading digit in interface");

my $ins = Net::DBus::Exporter::_dbus_introspector(ref($obj));

ok($ins->has_interface("org.example.MyObject"), "interface registration");
ok(!$ins->has_interface("org.example.BogusObject"), "-ve interface registration");

my $wantxml = <<EOF;
<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/org/example/MyObject">
  <interface name="_org.example._some_9object">
    <method name="DemoInterfaceName1">
      <arg type="s" direction="out"/>
    </method>
  </interface>
  <interface name="org.example.MyObject">
    <method name="Everything">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
    </method>
    <method name="EverythingAnnotate">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
      <annotation name="org.freedesktop.DBus.Method.NoReply" value="true"/>
    </method>
    <method name="EverythingNegativeAnnotate">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
    </method>
    <method name="NoArgs">
      <arg type="i" direction="out"/>
    </method>
    <method name="NoArgsAnnotate">
      <arg type="i" direction="out"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
    </method>
    <method name="NoArgsReturns">
    </method>
    <method name="NoArgsReturnsAnnotate">
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
    </method>
    <method name="NoReturns">
      <arg name="wizz" type="s" direction="in"/>
    </method>
    <method name="NoReturnsAnnotate">
      <arg type="s" direction="in"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
    </method>
  </interface>
  <interface name="org.example.OtherObject">
    <method name="EverythingInterface">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
    </method>
    <method name="EverythingInterfaceAnnotate">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
      <annotation name="org.freedesktop.DBus.Method.NoReply" value="true"/>
    </method>
    <method name="EverythingInterfaceNegativeAnnotate">
      <arg type="s" direction="in"/>
      <arg type="i" direction="out"/>
    </method>
    <method name="NoArgsInterface">
      <arg type="i" direction="out"/>
    </method>
    <method name="NoArgsInterfaceAnnotate">
      <arg name="two" type="i" direction="out"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
    </method>
    <method name="NoArgsReturnsInterface">
    </method>
    <method name="NoArgsReturnsInterfaceAnnotate">
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
    </method>
    <method name="NoReturnsInterface">
      <arg type="s" direction="in"/>
    </method>
    <method name="NoReturnsInterfaceAnnotate">
      <arg name="one" type="s" direction="in"/>
      <annotation name="org.freedesktop.DBus.Deprecated" value="true"/>
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

is ($ins->format($obj), $wantxml, "xml matches");


&check_method($ins, "Everything", ["string"], ["int32"], "org.example.MyObject", 0, 0);
&check_method($ins, "EverythingInterface", ["string"], ["int32"], "org.example.OtherObject", 0, 0);
&check_method($ins, "EverythingAnnotate", ["string"], ["int32"], "org.example.MyObject", 1, 1);
&check_method($ins, "EverythingNegativeAnnotate", ["string"], ["int32"], "org.example.MyObject", 0, 0);
&check_method($ins, "EverythingInterfaceAnnotate", ["string"], ["int32"], "org.example.OtherObject", 1, 1);
&check_method($ins, "EverythingInterfaceNegativeAnnotate", ["string"], ["int32"], "org.example.OtherObject", 0, 0);

&check_method($ins, "NoArgsReturns", [], [], "org.example.MyObject", 0, 0);
&check_method($ins, "NoReturns", ["string"], [], "org.example.MyObject", 0, 0);
&check_method($ins, "NoArgs", [], ["int32"], "org.example.MyObject", 0, 0);
&check_method($ins, "NoArgsReturnsInterface", [], [], "org.example.OtherObject", 0, 0);
&check_method($ins, "NoReturnsInterface", ["string"], [], "org.example.OtherObject", 0, 0);
&check_method($ins, "NoArgsInterface", [], ["int32"], "org.example.OtherObject", 0, 0);

&check_method($ins, "NoArgsReturnsAnnotate", [], [], "org.example.MyObject", 1, 0);
&check_method($ins, "NoReturnsAnnotate", ["string"], [], "org.example.MyObject", 1, 0);
&check_method($ins, "NoArgsAnnotate", [], ["int32"], "org.example.MyObject", 1, 0);
&check_method($ins, "NoArgsReturnsInterfaceAnnotate", [], [], "org.example.OtherObject", 1, 0);
&check_method($ins, "NoReturnsInterfaceAnnotate", ["string"], [], "org.example.OtherObject", 1, 0);
&check_method($ins, "NoArgsInterfaceAnnotate", [], ["int32"], "org.example.OtherObject", 1, 0);


sub check_method {
    my $ins = shift;
    my $name = shift;
    my $params = shift;
    my $returns = shift;
    my $interface = shift;
    my $deprecated = shift;
    my $no_return = shift;
    
    my @interfaces = $ins->has_method($name);
    is_deeply([$interface], \@interfaces, "method interface mapping");

    my @params = $ins->get_method_params($interface, $name);
    is_deeply($params, \@params, "method parameters");

    my @returns = $ins->get_method_returns($interface, $name);
    is_deeply($returns, \@returns, "method returneters");
    
    if ($deprecated) {
	ok($ins->is_method_deprecated($name, $interface), "method deprecated");
    } else {
	ok(!$ins->is_method_deprecated($name, $interface), "method deprecated");
    }


    if ($no_return) {
	ok(!$ins->does_method_reply($name, $interface), "method no reply");
    } else {
	ok($ins->does_method_reply($name, $interface), "method no reply");
    }


}
