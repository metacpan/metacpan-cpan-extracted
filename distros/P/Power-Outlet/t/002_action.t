# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 40;

BEGIN { use_ok( 'Power::Outlet' ); }
BEGIN { use_ok( 'Power::Outlet::Common' ); }

{
my $object = Power::Outlet->new(type=>"Common");
isa_ok ($object, 'Power::Outlet::Common');
can_ok($object, qw{action});

is($object->on, "ON", "on");
is($object->action("query"), "ON", "query");
is($object->action("QUERY"), "ON", "query");

is($object->action("off"),   "OFF", "off");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");


is($object->action("on"),    "ON", "on");
is($object->action("query"), "ON", "query");
is($object->action("QUERY"), "ON", "query");

is($object->action("OFF"),   "OFF", "OFF");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

is($object->action(1),       "ON", "action 1");
is($object->action("query"), "ON", "query");
is($object->action("QUERY"), "ON", "query");

is($object->action(0),       "OFF", "action 0");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

is($object->action("SWITCH"),"ON", "SWITCH");
is($object->action("query"), "ON", "query");
is($object->action("QUERY"), "ON", "query");

is($object->action("switch"),"OFF", "switch");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

is($object->action("TOGGLE"),"ON", "TOGGLE");
is($object->action("query"), "ON", "query");
is($object->action("QUERY"), "ON", "query");

is($object->action("toggle"),"OFF", "toggle");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

is($object->action("cycle"),"OFF", "cycle");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

is($object->action("CYCLE"),"OFF", "CYCLE");
is($object->action("query"), "OFF", "query");
is($object->action("QUERY"), "OFF", "query");

}
