#!perl

use strict;
use warnings;
use Test::More tests => 20;

use Encode qw();
use No::Worries::Syslog qw(*);

our($tmp);

# simple tests

sub test1 ($) {
    my($string) = @_;

    ok(length($string) <= $No::Worries::Syslog::MaximumLength, "length");
    like($string, qr/^[\x20-\x7e]*$/, "content");
}

{
    # silently create a malformed UTF-8 string (UTF-16 surrogate)
    no warnings "utf8";
    $tmp = "A\x{D800}B";
}

foreach ("",			            # empty string
	 "A" x 12345,		            # very long string
	 "Gen\x{e8}ve",		            # accentuated characters
	 "Hello \x{263a}",	            # Unicode wide character
	 join("", map(chr($_), 0 .. 255)),  # all characters
	 $tmp,				    # invalid Unicode string
    ) {
    test1(syslog_sanitize($_));
}

# advanced tests

sub bytes2hex ($) {
    my($string) = @_;
    my(@result, $byte);

    foreach $byte (unpack("C*", $string)) {
	push(@result, sprintf("%02X", $byte));
    }
    return("@result");
}

sub test2 ($$) {
    my($str1, $str2) = @_;

    $str1 = syslog_sanitize($str1);
    is($str1, $str2, "equal");
    is(bytes2hex($str1), bytes2hex($str2), "identical");
}

# trailing spaces are trimmed
test2(" \t\n\r" x 512, "");

# is_utf8() not set so no UTF-8 encoding
test2("Gen\x{e8}ve", "Gen%E8ve#E");

# is_utf8() set but encoded identical to source
test2(substr("Hello \x{263a}", 0, 5), "Hello");

# tabs are replaced so not encoded
test2("foo\tbar\t", "foo    bar");
