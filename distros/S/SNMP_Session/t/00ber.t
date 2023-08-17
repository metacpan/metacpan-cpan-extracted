#!/usr/bin/perl
###
### Test BER.pm encoding and decoding routines

use strict;
use warnings;

use Test::More tests => 15;
use BER;

### en_decode_test VALUE, ENCODER, TEMPLATE [, ENCODED]
###
### Test both encoding and decoding.
###
sub en_decode_test ($$$@) {
    my ($value, $encoder, $template, $encoded) = @_;
    if (defined $encoded) {
	is(&$encoder ($value), $encoded);
    } else {
	$encoded = &$encoder ($value);
    }
    my ($x) = decode_by_template ($encoded, $template);
    is($x, $value);
}

### tt PDU, TEMPLATE, EXPECTED, ARGS...
###
### Test decoding by template.  The PDU is decoded using TEMPLATE and
### (optionally) ARGS.  The resulting values are then compared against
### EXPECTED, which is a reference to a vector of expected values.
###
sub tt ($$$@) {
    my ($pdu, $template, $desired_result, @args) = @_;
    my @values = decode_by_template ($pdu, $template, @args);
    print "# ".join ("; ", @values)."\n";
    is_deeply (\@values, $desired_result);
}

en_decode_test ("foo", \&encode_string, "%s", "\x04\x03foo");
en_decode_test (123, \&encode_int, "%i", "\x02\x01\x7b");
is (encode_oid (1,3,6,1), "\x06\x03\x2b\x06\x01");
tt ("\x02\x01\x03", "%i", [3]);
tt ("\x02\x01\x03", "%u", [3]);
tt ("\x02\x01\xff", "%i", [-1]);
tt ("\x30\x03\x02\x01\xff", "%{%i", [-1]);
tt ("\x30\x0b\x02\x01\x12\x02\x01\x02\x04\x03foo", "%{%i%i%s", [18, 2, "foo"]);
tt ("\x30\x0b\x02\x01\x12\x02\x01\x02\x04\x03foo", "%{%i%2i%s", [18, "foo"]);
tt ("\x30\x0b\x02\x01\x12\x02\x01\x02\x04\x03foo", "%{%i%2i%*s", [18], "foo");
tt ("\x04\x03foo", "%s", ["foo"]);
tt ("\x38\x03\x02\x01\xff", "%*{%i", [-1], 0x38);
is (join (":",decode_sequence ("\x30\x05\x02\x00\x02\x01\x01\x30\x05\x02\x00\x02\x01\x01")),
    "\x02\x00\x02\x01\x01:\x30\x05\x02\x00\x02\x01\x01");
