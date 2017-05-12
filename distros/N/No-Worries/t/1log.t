#!perl

use strict;
use warnings;
use Test::More tests => 31;

use No::Worries::Log qw(*);

#
# wants wrt. filter & levels
#

sub test_wants ($$) {
    my($what, $expected) = @_;
    my($actual);

    $actual = "";
    $actual .= "i" if log_wants_info();
    $actual .= "d" if log_wants_debug();
    $actual .= "t" if log_wants_trace();
    is($actual, $expected, "wants ($what)");
}

test_wants("default", "i");
log_filter("debug message=~foo karma>10\ndebug line==1 xxx==");
test_wants("filter 1", "d");
log_filter("debug message!~foo karma<=10\nline!=1");
test_wants("filter 2", "idt");
log_filter("# comment\n\n\n\ninfo");
test_wants("filter 3", "i");

#
# formatting
#

$No::Worries::Log::Handler = sub ($) {
    my($info) = @_;
    return($info->{message});
};

is(log_info(), "", "format void");
is(log_info(""), "", "format empty");
is(log_info("abc%d"), "abc%d", "format string");
is(log_info("abc%d", 1), "abc1", "format sprintf");
is(log_info("%s", "program"), "program", "format sprintf");
is(log_info("%s", \"program"), "1log.t", "format sprintf hack");
is(log_info(sub { return("yeah") }), "yeah", "format code");
is(log_info(sub { return("yeah @_") }, "too"), "yeah too", "format code with args");

#
# filtering
#

sub foo () {
    log_debug("whatever");
}

$No::Worries::Log::Handler = sub ($) { return("fine") };

log_filter("debug");
is(log_info("whatever"), "0", "filter 1 - no");
is(log_debug("whatever"), "fine", "filter 1 - yes");

log_filter("debug caller==main");
is(foo(), "0", "filter 2 - no");
is(log_debug("whatever"), "fine", "filter 2 - yes");

log_filter("debug caller=~\\bfoo\$");
is(log_debug("whatever"), "0", "filter 3 - no");
is(foo(), "fine", "filter 3 - yes");

log_filter("debug and karma<7 or trace");
is(log_debug("whatever"), "0", "filter 4 - no");
is(log_debug("whatever", { karma => 7 }), "0", "filter 4 - no");
is(log_debug("whatever", { karma => 3 }), "fine", "filter 4 - yes");

#
# errors
#

eval { log_filter("foobar") };
ok($@ ne "", "error filter");
eval { log_filter("level==debug") };
ok($@ ne "", "error level");
eval { log_filter("debug trace") };
ok($@ ne "", "error multiple levels");

log_filter("info");
eval { log_info([ 1, 2 ]) };
ok($@ ne "", "error []");
eval { log_info("whatever", undef) };
ok($@ ne "", "error undef");
eval { log_info("whatever", []) };
ok($@ ne "", "error [] arg");
eval { log_info("whatever", {}, {}) };
ok($@ ne "", "error {} arg");
eval { log_info("whatever", \"buggy") };
ok($@ ne "", "error unknown attribute");

#
# filter and code reference
#

my($called);

sub expensive () {
    $called = 1;
    return("anything");
}

sub test_filter_code () {
    log_debug(\&expensive);
}

log_filter("debug");
$called = 0;
test_filter_code();
is($called, 1, "filter + code - yes");

log_filter("debug and caller!~test_filter_code");
$called = 0;
test_filter_code();
is($called, 0, "filter + code - no");
