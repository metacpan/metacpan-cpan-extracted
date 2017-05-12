#!/usr/bin/perl

# Test the attribute overriding code as well as access to the
# attribute stack

# $Id: attrover.t 56 2007-01-08 20:52:18Z lem $


no utf8;
use IO::File;
use Test::More 'no_plan';
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	Reply-Message		18	string
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($d, 'Net::Radius::Dictionary');

# Build a request and test it is ok
my $p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x66" x 16);
$p->set_code("Access-Reject");
$p->set_attr("Reply-Message" => 'line-1');
$p->set_attr("Reply-Message" => 'line-2', 1);

# There should be one attribute, a single Reply-Message
is($p->attr_slots, 1, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0");
is($p->attr_slot_val(0), 'line-2', "Correct value for slot 0");

is($p->attr_slot_name(1), undef, "Undef slot 1 name");
is($p->attr_slot_val(1), undef, "Undef slot 1 value");

# Now there should be 3 attributes

$p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x66" x 16);
$p->set_code("Access-Reject");
$p->set_attr("Reply-Message" => 'line-1');
$p->set_attr("Reply-Message" => 'line-2');
$p->set_attr("Reply-Message" => 'line-3', 1);

is($p->attr_slots, 3, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0");
is($p->attr_slot_val(0), 'line-1', "Correct value for slot 0");

is($p->attr_slot_name(1), 'Reply-Message', "Correct name for slot 1");
is($p->attr_slot_val(1), 'line-2', "Correct value for slot 1");

is($p->attr_slot_name(2), 'Reply-Message', "Correct name for slot 2");
is($p->attr_slot_val(2), 'line-3', "Correct value for slot 2");

is($p->attr_slot_name(3), undef, "Undef slot 3 name");
is($p->attr_slot_val(3), undef, "Undef slot 3 value");
