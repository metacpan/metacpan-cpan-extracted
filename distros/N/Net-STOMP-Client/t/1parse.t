#!perl

use strict;
use warnings;
use Net::STOMP::Client::Frame qw();
use Test::More tests => 261;

sub test ($$$) {
    my($name, $expect, $data) = @_;
    my($state, $result, $key);

    if ($expect) {
	$state = {};
	$result = Net::STOMP::Client::Frame::parse(\$data, state => $state);
	if ($expect->{total_len}) {
	    ok($result, "$name (parse - complete)");
	} else {
	    ok(!$result, "$name (parse - incomplete)");
	}
	foreach $key (sort(keys(%$expect))) {
	    is($state->{$key}, $expect->{$key}, "$name ($key)");
	}
	foreach $key (sort(keys(%$state))) {
	    next if exists($expect->{$key});
	    is($state->{$key}, undef, "$name ($key)");
	}
    } else {
	eval { Net::STOMP::Client::Frame::parse(\$data) };
	ok($@, "$name (error)");
    }
}

my(%state);

%state = ();
test("empty", \%state, "");
test("eol1",  \%state, "\n");
test("eol1",  \%state, "\r");
test("eol2",  \%state, "\r\n");
test("eol2",  \%state, "\n\r");
test("eol2",  \%state, "\n\n");
test("eol2",  \%state, "\r\r");
test("eol7",  \%state, "\n\r\n\r\n\r\n");
test("eol7",  \%state, "\r\n\r\n\r\n\r");

%state = (before_len => 0, command_idx => 0);
test("cmd1", \%state, "FOO");
test("cmd2", \%state, "FOO\r");

%state = (%state, command_len => 3, header_idx => 3);
test("cmd3", { %state, command_eol => 1 }, "FOO\n");
test("cmd4", { %state, command_eol => 2 }, "FOO\r\n");

$state{header_len} = 0;
$state{command_eol} = 1;
test("no-hdr1", { %state, header_eol => 2, body_idx => 5 }, "FOO\n\n");
test("no-hdr2", { %state, header_eol => 3, body_idx => 6 }, "FOO\n\r\n");
$state{command_eol} = 2;
test("no-hdr3", { %state, header_eol => 3, body_idx => 6 }, "FOO\r\n\n");
test("no-hdr4", { %state, header_eol => 4, body_idx => 7 }, "FOO\r\n\r\n");

$state{command_eol} = 1;
$state{header_eol} = 2;
$state{body_idx} = 5;
$state{body_len} = 0;
$state{after_idx} = 6;
test("no-hdr+no-body1", { %state, after_len => 0, total_len => 6 }, "FOO\n\n\0");
test("no-hdr+no-body2", { %state, after_len => 1, total_len => 7 }, "FOO\n\n\0\n");
test("no-hdr+no-body3", { %state, after_len => 1, total_len => 7 }, "FOO\n\n\0\r");
test("no-hdr+no-body4", { %state, after_len => 3, total_len => 9 }, "FOO\n\n\0\n\r\n");
test("no-hdr+no-body5", { %state, after_len => 3, total_len => 9 }, "FOO\n\n\0\r\n\r");
test("no-hdr+no-body6", { %state, after_len => 0, total_len => 6 }, "FOO\n\n\0BAR");

$state{body_len} = 4;
$state{after_idx} = 10;
$state{after_len} = 0;
$state{total_len} = $state{after_idx};
test("no-hdr+body1", { %state }, "FOO\n\nbody\0");
test("no-hdr+body2", { %state }, "FOO\n\nbody\0double\0");

$state{header_idx} = 4;
$state{header_len} = 6;
$state{body_len} = 0;
$state{after_len} = 0;
test("hdr+no-body1", { %state, header_eol => 2, body_idx => 12, after_idx => 13, total_len => 13 }, "FOO\nid:123\n\n\0");
test("hdr+no-body2", { %state, header_eol => 3, body_idx => 13, after_idx => 14, total_len => 14 }, "FOO\nid:123\n\r\n\0");
test("hdr+no-body3", { %state, header_eol => 3, body_idx => 13, after_idx => 14, total_len => 14 }, "FOO\nid:123\r\n\n\0");
test("hdr+no-body4", { %state, header_eol => 4, body_idx => 14, after_idx => 15, total_len => 15 }, "FOO\nid:123\r\n\r\n\0");

$state{header_len} = 16;
$state{header_eol} = 2;
$state{body_idx} = 22;
test("hdr+body1", { %state, content_length => 4, body_len => 4, after_idx => 27, total_len => 27 }, "FOO\ncontent-length:4\n\nbody\0x\0y\0");
test("hdr+body2", { %state, content_length => 6, body_len => 6, after_idx => 29, total_len => 29 }, "FOO\ncontent-length:6\n\nbody\0x\0y\0");

%state = (
    before_len  =>  1,
    command_idx =>  1,
    command_len =>  3,
    command_eol =>  1,
    header_idx  =>  5,
    header_len  =>  4,
    header_eol  =>  3,
    body_idx    => 12,
    body_len    =>  5,
    after_idx   => 18,
    after_len   =>  1,
    total_len   => 19,
);
test("hdr+body3", \%state, "\nFOO\nid:1\r\n\n\rfoo\n\0\n");

test("missing NULL", 0, "FOO\ncontent-length:3\r\n\nfoo\n");

__DATA__

#
# to be put in decode.t
#

test("bad command", EXPECT_ERROR, "foo\n\n\0");
test("bad headers", EXPECT_ERROR, "FOO\nid=123\n\n\0");
test("bad headers", EXPECT_ERROR, "FOO\n:123\n\n\0");

test("no escape (1.0)", EXPECT_COMPLETE, "FOO\nfoo:bar\\gag\n\n\0", "1.0");
test("bad escape (1.1)", EXPECT_ERROR,   "FOO\nfoo:bar\\gag\n\n\0", "1.1");

