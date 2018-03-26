#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2018 Joelle Maslak
# All Rights Reserved - See License
#

# This tests that object destruction returns a warning in the common
# case (on non-Win32) when there are children still running.

use strict;
use warnings;
use autodie;

use Carp;

use Test2::V0;

use Parallel::WorkUnit;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120;    # It would be nice if we did this a better way, since
              # strictly speaking, 120 seconds isn't necessarily
              # indicative of failure if running this on a VERY
              # slow machine.
              # But hopefully nobody has that slow of a machine!

my $wu = Parallel::WorkUnit->new();
ok( defined($wu), "Constructer returned object" );

my $wu2 = Parallel::WorkUnit->new();
ok( defined($wu2), "Constructer returned second object" );

$wu2->async( sub { sleep 1; return -9; } );

$wu->async(
    sub {
        $wu->async( sub { return 42; } );
        $wu2->async( sub { return -42; } );
        return [ $wu->waitall, $wu2->waitall ];
    }
);

my (@result) = $wu->waitall();
is(\@result, [ [ 42, -42 ] ], "Nested work units function properly");

@result = $wu2->waitall();
is(\@result, [ -9 ], "Second waitall in main process functions properly" );

done_testing();

