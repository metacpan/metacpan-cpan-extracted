#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2019 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use Carp;

use Test2::V0;

use Parallel::WorkUnit;
use Symbol;

# Test only with threads
eval 'use threads qw//; 1' or skip_all("This is not a threaded Perl");

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120;    # It would be nice if we did this a better way, since
              # strictly speaking, 120 seconds isn't necessarily
              # indicative of failure if running this on a VERY
              # slow machine.
              # But hopefully nobody has that slow of a machine!

# Undocumented "force threading" variable
$Parallel::WorkUnit::use_threads = 1;

my $wu = Parallel::WorkUnit->new();
ok( defined($wu), "Constructer returned object" );

pipe my $rfh, my $wfh;

$wu->start( sub { print $wfh "TeStInG\n"; close $wfh } );

while ( my $result = <$rfh> ) {
    chomp $result;
    is( $result, 'TeStInG', "Child process ran properly" );
    last;
}
close $rfh;

done_testing();

