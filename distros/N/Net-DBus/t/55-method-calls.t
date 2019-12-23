# -*- perl -*-

use Test::More tests => 56;

use strict;
use warnings;

BEGIN { 
    use_ok('Net::DBus::Binding::Introspector') or die;
    use_ok('Net::DBus::Object') or die;
    use_ok('Net::DBus::Test::MockObject') or die;
};


TEST_NO_INTROSPECT: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;

    $object->seed_action("org.freedesktop.DBus.Introspectable", "Introspect", 
			 error => { name => "org.freedesktop.DBus.Error.UnknownMethod",
				    description => "No such method" });

    &test_method_fail("raw, no introspect", $robject, "Test");
    &test_method_reply("myobject, no introspect",$myobject, "Test", "TestedMyObject");
    &test_method_fail("otherobject, no introspect",$otherobject, "Test");

    &test_method_fail("raw, no introspect",$robject, "Bogus");
    &test_method_fail("myobject, no introspect",$myobject, "Bogus");
    &test_method_fail("otherobject, no introspect",$otherobject, "Bogus");

    &test_method_fail("raw, no introspect",$robject, "PolyTest");
    &test_method_reply("myobject, no introspect",$myobject, "PolyTest", "PolyTestedMyObject");
    &test_method_reply("otherobject, no introspect",$otherobject, "PolyTest", "PolyTestedOtherObject");

    &test_method_fail("raw, no introspect", $robject, "Deprecated");
    &test_method_reply("myobject, no introspect",$myobject, "Deprecated", "TestedDeprecation");
    &test_method_fail("otherobject, no introspect",$otherobject, "Deprecated");
}

TEST_MISSING_INTROSPECT: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;

    my $ins = Net::DBus::Binding::Introspector->new(object_path => $object->get_object_path);    
    $object->seed_action("org.freedesktop.DBus.Introspectable", "Introspect", 
			 reply => { return => [ $ins->format ] });
    

    &test_method_fail("raw, missing introspect",$robject, "Test");
    &test_method_reply("myobject, missing introspect",$myobject, "Test", "TestedMyObject");
    &test_method_fail("otherobject, missing introspect",$otherobject, "Test");

    &test_method_fail("raw, missing introspect",$robject, "Bogus");
    &test_method_fail("myobject, missing introspect",$myobject, "Bogus");
    &test_method_fail("otherobject, missing introspect",$otherobject, "Bogus");

    &test_method_fail("raw, missing introspect",$robject, "PolyTest");
    &test_method_reply("myobject, missing introspect",$myobject, "PolyTest", "PolyTestedMyObject");
    &test_method_reply("otherobject, missing introspect",$otherobject, "PolyTest", "PolyTestedOtherObject");

    &test_method_fail("raw, no introspect", $robject, "Deprecated");
    &test_method_reply("myobject, no introspect",$myobject, "Deprecated", "TestedDeprecation");
    &test_method_fail("otherobject, no introspect",$otherobject, "Deprecated");
}

TEST_FULL_INTROSPECT: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;

    my $ins = Net::DBus::Binding::Introspector->new(object_path => $object->get_object_path);
    $ins->add_method("Test", [], ["string"], "org.example.MyObject", {}, []);
    $ins->add_method("PolyTest", [], ["string"], "org.example.MyObject", {}, []);
    $ins->add_method("PolyTest", [], ["string"], "org.example.OtherObject", {}, []);
    $ins->add_method("Deprecated", [], ["string"], "org.example.MyObject", { deprecated => 1 }, []);
    $object->seed_action("org.freedesktop.DBus.Introspectable", "Introspect", 
			 reply => { return => [ $ins->format ] });
    

    &test_method_reply("raw, full introspect",$robject, "Test", "TestedMyObject");
    &test_method_reply("myobject, full introspect",$myobject, "Test", "TestedMyObject");
    &test_method_fail("otherobject, full introspect",$otherobject, "Test");

    &test_method_fail("raw, full introspect",$robject, "Bogus");
    &test_method_fail("myobject, full introspect",$myobject, "Bogus");
    &test_method_fail("otherobject, full introspect",$otherobject, "Bogus");

    &test_method_fail("raw, full introspect",$robject, "PolyTest");
    &test_method_reply("myobject, full introspect",$myobject, "PolyTest", "PolyTestedMyObject");
    &test_method_reply("otherobject, full introspect",$otherobject, "PolyTest", "PolyTestedOtherObject");
    
    {
	my $warned = 0;
	local $SIG{__WARN__} = sub {
	    if ($_[0] eq "method 'Deprecated' in interface org.example.MyObject on object /org/example/MyObject is deprecated\n") {
		$warned = 1;
	    }
	};
	&test_method_reply("raw, no introspect", $robject, "Deprecated", "TestedDeprecation");
	ok($warned, "deprecation warning generated");
	$warned = 0;
	&test_method_reply("myobject, no introspect",$myobject, "Deprecated", "TestedDeprecation");
	ok($warned, "deprecation warning generated");
	$warned = 0;
	&test_method_fail("otherobject, no introspect",$otherobject, "Deprecated");
	ok(!$warned, "deprecation warning generated");
    }
}


sub setup {
    my $bus = Net::DBus->test;
    my $service = $bus->export_service("org.cpan.Net.Bus.test");
    
    my $object = Net::DBus::Test::MockObject->new($service, "/org/example/MyObject");
    
    my $rservice = $bus->get_service("org.cpan.Net.Bus.test");
    my $robject = $rservice->get_object("/org/example/MyObject");
    my $myobject = $robject->as_interface("org.example.MyObject");
    my $otherobject = $robject->as_interface("org.example.OtherObject");

    $object->seed_action("org.example.MyObject", "Test", reply => { return => [ "TestedMyObject" ] });
    $object->seed_action("org.example.MyObject", "PolyTest", reply => { return => [ "PolyTestedMyObject" ] });
    $object->seed_action("org.example.OtherObject", "PolyTest", reply => { return => [ "PolyTestedOtherObject" ] });
    $object->seed_action("org.example.MyObject", "Deprecated", reply => { return => [ "TestedDeprecation" ]});
    $object->seed_action("org.example.MyObject", "TestNoReturn");
    
    return ($bus, $object, $robject, $myobject, $otherobject);
}

sub test_method_noreply {
    my $tag = shift;
    my $object = shift;
    my $method = shift;
    
    my $actual = eval {
	$object->$method;
    };
    is($@, "", "error is not thrown by '$method' ($tag)");
    ok(!$actual, "return from '$method' is undefined ($tag)");
}

sub test_method_reply {
    my $tag = shift;
    my $object = shift;
    my $method = shift;
    my $expect = shift;
    
    my $actual = eval {
	$object->$method;
    };
    is($@, "", "error is not thrown by '$method' ($tag)");
    is($actual, $expect, "return from '$method' is '$actual' ($tag)");
}

sub test_method_fail {
    my $tag = shift;
    my $object = shift;
    my $method = shift;
    
    my $actual = eval {
	$object->$method;
    };
    ok($@, "error is thrown by '$method' ($tag)");
}
