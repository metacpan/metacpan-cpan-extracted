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

# Instantiate the object

like(
    warning {
        do {
            my $wu = Parallel::WorkUnit->new();
            ok( defined($wu), "Constructer returned object" );
            $wu->queue( sub { sleep 1; } );
        };
    },
    qr/Subprocesses running/,
    "Got warning for running sub processes",
);

done_testing();

