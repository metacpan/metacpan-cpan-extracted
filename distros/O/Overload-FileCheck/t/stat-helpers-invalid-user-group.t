#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Overload::FileCheck q{:stat};

# Verify that passing a nonexistent username to uid croaks
like(
    dies { stat_as_file( uid => 'zzzz_no_such_user_xyzzy' ) },
    qr/Unknown user 'zzzz_no_such_user_xyzzy'/,
    'stat_as_file croaks on unknown username',
);

# Verify that passing a nonexistent groupname to gid croaks
like(
    dies { stat_as_file( gid => 'zzzz_no_such_group_xyzzy' ) },
    qr/Unknown group 'zzzz_no_such_group_xyzzy'/,
    'stat_as_file croaks on unknown groupname',
);

# Numeric uid/gid should still work fine (no croak)
my $stat = stat_as_file( uid => 99999, gid => 99999 );
is $stat->[4], 99999, 'numeric uid passes through';
is $stat->[5], 99999, 'numeric gid passes through';

# Unknown option keys are rejected (catches typos)
like(
    dies { stat_as_file( szie => 42 ) },
    qr/Unknown option 'szie'/,
    'stat_as_file croaks on typo key',
);

like(
    dies { stat_as_directory( foo => 1 ) },
    qr/Unknown option 'foo'/,
    'stat_as_directory croaks on unknown key',
);

# 'mode' gets a specific helpful message
like(
    dies { stat_as_file( mode => 0100755 ) },
    qr/use 'perms' for permission bits/,
    'stat_as_file gives helpful message for mode key',
);

# Known keys still work (no regression)
is stat_as_file( size => 100, mtime => 999 )->[7], 100, 'size still works';
is stat_as_file( size => 100, mtime => 999 )->[9], 999, 'mtime still works';
is stat_as_file( perms => 0755 )->[2] & 0777, 0755, 'perms still works';

done_testing;
