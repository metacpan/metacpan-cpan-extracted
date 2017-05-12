#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

use String::Range::Expand qw(expand_expr);

# Autoflush ON
local $| = 1;

# Test Expansion
is_deeply(
    [
        expand_expr(
            'foo-bar[01-03] host[aa-ad,^ab]Z[01-04,^02-03].name, web')
    ], [
        "foo-bar01",      "foo-bar02",
        "foo-bar03",      "hostaaZ01.name",
        "hostaaZ04.name", "hostacZ01.name",
        "hostacZ04.name", "hostadZ01.name",
        "hostadZ04.name", "web",
    ],
    "Expansion OK!",
);

# Done
done_testing();
exit 0;
