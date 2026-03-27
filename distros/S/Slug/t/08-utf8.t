#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 8;
use Slug qw(slug);

# Multi-byte UTF-8 sequences (constructed as byte strings with utf8 upgrade)
# 2-byte: U+00E9 (é) = C3 A9
my $e_acute = "\xc3\xa9";
utf8::decode($e_acute);
is(slug("caf${e_acute}"), "cafe", "2-byte UTF-8 (é)");

# 3-byte: U+2019 (right single quote) = E2 80 99
my $rsq = "\xe2\x80\x99";
utf8::decode($rsq);
is(slug("it${rsq}s"), "it-s", "3-byte UTF-8 (right single quote)");

# 3-byte: U+20AC (€) = E2 82 AC
my $euro = "\xe2\x82\xac";
utf8::decode($euro);
is(slug("50${euro}"), "50eur", "3-byte UTF-8 (€)");

# Mixed byte lengths
my $mixed = "caf\xc3\xa9 \xe2\x82\xac" . "50";
utf8::decode($mixed);
is(slug($mixed), "cafe-eur50", "mixed 1/2/3-byte sequences");

# Pure ASCII (no UTF-8 decoding needed)
is(slug("simple test"), "simple-test", "pure ASCII fast path");

# Latin Extended Additional (4-byte at input layer)
# U+1E00 = Ḁ -> A (3-byte UTF-8: E1 B8 80)
my $a_ring_below = "\xe1\xb8\x80";
utf8::decode($a_ring_below);
is(slug("${a_ring_below}pple"), "apple", "Latin Extended Additional");

# Combining characters that are not in the table get dropped
my $combining = "a\xcc\x81";  # a + combining acute U+0301
utf8::decode($combining);
my $result = slug($combining);
ok($result eq "a" || $result eq "a-a", "combining accent handled");

# Empty UTF-8 string
is(slug(""), "", "empty string");
