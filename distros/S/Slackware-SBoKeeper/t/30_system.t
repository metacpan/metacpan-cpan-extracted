#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper::System;

my @SLACKWARE_VERSIONS = qw(
    1.0   1.1   2.0
    2.1   2.2   2.3
    3.1   3.2   3.3
    3.4   3.5   3.6
    3.9   4.0   7.0
    7.1   8.0   8.1
    9.0   9.1   10.0
    10.1  10.2  11.0
    12.0  12.1  12.2
    13.0  13.1  13.37
    14.0  14.1  14.2
    15.0
);

if (Slackware::SBoKeeper::System->is_slackware()) {
	plan tests => 3;
} else {
	plan skip_all => 'Not a Slackware system';
}

ok(
	grep { Slackware::SBoKeeper::System->version() eq $_ } @SLACKWARE_VERSIONS,
	'Slackware version looks ok'
);

ok(
	-d Slackware::SBoKeeper::System->pkgtool_logs(),
	'pkgtool log directory exists'
);

ok(
	# Force list context
	(() = Slackware::SBoKeeper::System->packages()),
	'Successfully created package list'
);
