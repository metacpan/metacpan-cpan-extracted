#!/usr/bin/perl

# Test the attribute slot management

# $Id: attrslot.t 77 2007-01-30 15:15:48Z lem $


no utf8;
use IO::File;
use Test::More tests => 61;
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	integer
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

is($p->attr_slots, 0, "Correct number of attribute slots in empty packet");
is($p->attr_slot_name(0), undef, "Undefined slot 0 name (e)");
is($p->attr_slot_val(0), undef, "Undefined slot 0 value (e)");

$p->set_attr("Reply-Message" => 'line-1');
$p->set_attr("Reply-Message" => 'line-2');

my $q = new Net::Radius::Packet $d, $p->pack;
isa_ok($q, 'Net::Radius::Packet');

is($p->attr_slots, 2, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0");
is($p->attr_slot_val(0), 'line-1', "Correct value for slot 0");

is($p->attr_slot_name(1), 'Reply-Message', "Correct name for slot 1");
is($p->attr_slot_val(1), 'line-2', "Correct value for slot 1");

is($p->attr_slot_name(2), undef, "Undefined slot 2 name");
is($p->attr_slot_val(2), undef, "Undefined slot 2 value");

$q = new Net::Radius::Packet $d, $p->pack;
isa_ok($q, 'Net::Radius::Packet');

is($q->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0 (q)");
is($q->attr_slot_val(0), 'line-1', "Correct value for slot 0 (q)");

is($q->attr_slot_name(1), 'Reply-Message', "Correct name for slot 1 (q)");
is($q->attr_slot_val(1), 'line-2', "Correct value for slot 1 (q)");

is($q->attr_slot_name(2), undef, "Undefined slot 2 name (q)");
is($q->attr_slot_val(2), undef, "Undefined slot 2 value (q)");

# Add a third attribute to the packet and verify what happens

$p->set_attr("NAS-Port" => "42");
is($p->attr_slots, 3, "Correct number of attribute slots");

is($p->attr_slot_name(2), 'NAS-Port', "Correct name for slot 2");
is($p->attr_slot_val(2), '42', "Correct value for slot 2");

is($p->attr_slot_name(3), undef, "Undefined slot 3 name");
is($p->attr_slot_val(3), undef, "Undefined slot 3 value");

# Remove attr slot 1 and check what happened

$p->unset_attr_slot(1);

is($p->attr_slots, 2, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0 (q)");
is($p->attr_slot_val(0), 'line-1', "Correct value for slot 0 (q)");

is($p->attr_slot_name(1), 'NAS-Port', "Correct name for slot 1");
is($p->attr_slot_val(1), '42', "Correct value for slot 1");

is($p->attr_slot_name(2), undef, "Undefined slot 2 name");
is($p->attr_slot_val(2), undef, "Undefined slot 2 value");

# Remove an already unexistant slot

$p->unset_attr_slot(2);

is($p->attr_slots, 2, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0 (q)");
is($p->attr_slot_val(0), 'line-1', "Correct value for slot 0 (q)");

is($p->attr_slot_name(1), 'NAS-Port', "Correct name for slot 1");
is($p->attr_slot_val(1), '42', "Correct value for slot 1");

is($p->attr_slot_name(2), undef, "Undefined slot 2 name");
is($p->attr_slot_val(2), undef, "Undefined slot 2 value");

# Remove slot 1

$p->unset_attr_slot(1);

is($p->attr_slots, 1, "Correct number of attribute slots");

is($p->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0 (q)");
is($p->attr_slot_val(0), 'line-1', "Correct value for slot 0 (q)");

is($p->attr_slot_name(1), undef, "Undefined slot 1 name");
is($p->attr_slot_val(1), undef, "Undefined slot 1 value");

# Remove last slot

$p->unset_attr_slot(0);

is($p->attr_slots, 0, "Correct number of attribute slots");

is($p->attr_slot_name(0), undef, "Undefined slot 0 name");
is($p->attr_slot_val(0), undef, "Undefined slot 0 value");

# Remove last slot (again)

$p->unset_attr_slot(0);

is($p->attr_slots, 0, "Correct number of attribute slots");

is($p->attr_slot_name(0), undef, "Undefined slot 0 name");
is($p->attr_slot_val(0), undef, "Undefined slot 0 value");

# Remove first slot

$q->set_attr("NAS-Port" => "42");
is($q->attr_slots, 3, "Correct number of attribute slots");

is($q->attr_slot_name(2), 'NAS-Port', "Correct name for slot 2");
is($q->attr_slot_val(2), '42', "Correct value for slot 2");

is($q->attr_slot_name(3), undef, "Undefined slot 3 name");
is($q->attr_slot_val(3), undef, "Undefined slot 3 value");

$q->unset_attr_slot(0);

is($q->attr_slot_name(0), 'Reply-Message', "Correct name for slot 0 (q)");
is($q->attr_slot_val(0), 'line-2', "Correct value for slot 0 (q)");

is($q->attr_slot_name(1), 'NAS-Port', "Correct name for slot 1 (q)");
is($q->attr_slot_val(1), '42', "Correct value for slot 1 (q)");

is($q->attr_slot_name(2), undef, "Undefined slot 2 name (q)");
is($q->attr_slot_val(2), undef, "Undefined slot 2 value (q)");
