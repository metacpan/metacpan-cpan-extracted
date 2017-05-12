#!perl

use strict;
use warnings;
use Test::More tests => 28;

use No::Worries::Date qw(*);

use constant RE_STRING1 => qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/;
use constant RE_STRING2 => qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z$/;
use constant RE_STAMP1  => qr/^\d\d\d\d\/\d\d\/\d\d-\d\d:\d\d:\d\d$/;
use constant RE_STAMP2  => qr/^\d\d\d\d\/\d\d\/\d\d-\d\d:\d\d:\d\d\.\d+$/;

is(length(date_string()), 20, "date_string() length");
is(length(date_stamp()), 19, "date_stamp() length");

# equivalent times
sub test0 ($$) {
    my($time1, $time2) = @_;
    my($str1, $str2);

    $str1 = date_string($time1);
    $str2 = date_string($time2);
    is($str1, $str2, "date_string($time1) eq date_string($time2)");
    $str1 = date_stamp($time1);
    $str2 = date_stamp($time2);
    is($str1, $str2, "date_stamp($time1) eq date_stamp($time2)");
}

# integer time
sub test1 ($) {
    my($time) = @_;
    my($str, $tmp);

    $str = date_string($time);
    like($str, RE_STRING1, "date_string($time) match [integer]");
    $tmp = date_parse($str);
    is($time, $tmp, "time -> date_string$time() -> time [integer]");
    $str = date_stamp($time);
    like($str, RE_STAMP1, "date_stamp($time) match [integer]");
    $tmp = date_parse($str);
    is($time, $tmp, "time -> date_stamp($time) -> time [integer]");
}

# fractional time
sub test2 ($) {
    my($time) = @_;
    my($str, $tmp);

    $str = date_string($time);
    like($str, RE_STRING2, "date_string($time) match [fractional]");
    $tmp = date_parse($str);
    is($time, $tmp, "time -> date_string($time) -> time [fractional]");
    $str = date_stamp($time);
    like($str, RE_STAMP2, "date_stamp($time) match [fractional]");
    $tmp = date_parse($str);
    is($time, $tmp, "time -> date_stamp($time) -> time [fractional]");
}

our($time);

$time = time();

test1($time);
test2("$time.123");
if ($time =~ /^(\d)(\d+)$/) {
    test0($time, sprintf("%d.%dE+%d", $1, $2, length($2)));
    test0($time, sprintf("%d.%de%d", $1, $2, length($2)));
    test0("$time.123", sprintf("%d.%d123e%d", $1, $2, length($2)));
} else {
    die("ooops!");
}

foreach my $string (
    "Wed, 09 Feb 1994 22:23:32 GMT", # HTTP format
    "Thu Feb  3 17:03:55 GMT 1994",  # ctime(3) format
    "Thu Feb  3 00:00:00 1994",,     # ANSI C asctime() format
    "03/Feb/1994:17:03:55 -0700",    # common logfile format
    "09 Feb 1994 22:23:32 GMT",      # HTTP format (no weekday)
    "08-Feb-94 14:15:29 GMT",        # rfc850 format (no weekday)
    "1994-02-03 14:15:29 -0100",     # ISO 8601 format
    "1994-02-03 14:15:29",           # zone is optional
    "19940203T141529Z",              # ISO 8601 compact format
    ) {
    $time = date_parse($string);
    like($time, qr/^\d+$/, "parse $string");
}

eval { $time = date_parse("Not a date!") };
like($@, qr/invalid date:/, "invalid date");

eval { $time = date_string("Not a time!") };
like($@, qr/invalid time:/, "invalid time");

eval { $time = date_stamp("Not a time!") };
like($@, qr/invalid time:/, "invalid time");
