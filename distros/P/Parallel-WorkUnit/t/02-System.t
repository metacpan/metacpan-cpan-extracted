#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015 Joelle Maslak
# All Rights Reserved - See License
#

# This tests a bug reported by SREZIC - system SIGCHLD's were getting
# improperly reaped by the SIGCHLD handler.  This test validates that
# the exit value of a system execution is preserved.

use strict;
use warnings;
use autodie;

use Carp;
use Test::More tests => 3;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120; # It would be nice if we did this a better way, since
           # strictly speaking, 120 seconds isn't necessarily
           # indicative of failure if running this on a VERY
           # slow machine.
           # But hopefully nobody has that slow of a machine!

# Instantiate the object
require_ok('Parallel::WorkUnit');
my $wu = Parallel::WorkUnit->new();
ok(defined($wu), "Constructer returned object");

my $result;
%ENV=();
my $true;
if (-f '/bin/true') { $true = '/bin/true'; }
if (-f '/usr/bin/true') { $true = '/usr/bin/true'; }

SKIP: {
    skip("Can't find true binary", 1) unless defined($true);

    $wu->async(
        sub { system($true); return $? },
        sub { $result = shift; }
    );

    $wu->waitall();
    is($result, 0, 'System calls properly function');
}

