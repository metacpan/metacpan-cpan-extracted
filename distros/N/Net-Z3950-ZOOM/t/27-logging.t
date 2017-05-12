# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 27-logging.t'

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok('ZOOM') };

check_level("none", 0);
check_level("none,debug", 2);
check_level("none,warn", 4);
check_level("none,warn,debug", 6);
check_level("none,zoom", 16384);
check_level("none,-warn", 0);
check_level("", 2077);
check_level("-warn", 2073);
check_level("zoom", 18461);
check_level("none,zoom,fruit", 49152);

sub check_level {
    my($str, $expect) = @_;
    my $level = ZOOM::Log::mask_str($str);
    ok($level == $expect, "log-level for '$str' ($level, expected $expect)");
}

# See comment in "17-logging.t" on incompleteness of test-suite.

