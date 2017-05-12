#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

use String::Range::Expand qw(expand_range);

# Autoflush ON
local $| = 1;

# Test Expansion
is_deeply(
    [
        expand_range(
            'foo-bar[01-03] host[aa-ad,^ab]Z[01-04,^02-03].name, web')
    ], [
        'foo-bar01 hostaaZ01.name, web',
        'foo-bar01 hostaaZ04.name, web',
        'foo-bar01 hostacZ01.name, web',
        'foo-bar01 hostacZ04.name, web',
        'foo-bar01 hostadZ01.name, web',
        'foo-bar01 hostadZ04.name, web',
        'foo-bar02 hostaaZ01.name, web',
        'foo-bar02 hostaaZ04.name, web',
        'foo-bar02 hostacZ01.name, web',
        'foo-bar02 hostacZ04.name, web',
        'foo-bar02 hostadZ01.name, web',
        'foo-bar02 hostadZ04.name, web',
        'foo-bar03 hostaaZ01.name, web',
        'foo-bar03 hostaaZ04.name, web',
        'foo-bar03 hostacZ01.name, web',
        'foo-bar03 hostacZ04.name, web',
        'foo-bar03 hostadZ01.name, web',
        'foo-bar03 hostadZ04.name, web',
    ],
    "Expansion OK!",
);

# Done
done_testing();
exit 0;
