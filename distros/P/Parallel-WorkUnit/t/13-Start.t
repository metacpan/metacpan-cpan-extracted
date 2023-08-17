#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2020 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use Carp;

use Test2::V0;

use Symbol;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120;    # It would be nice if we did this a better way, since
              # strictly speaking, 120 seconds isn't necessarily
              # indicative of failure if running this on a VERY
              # slow machine.
              # But hopefully nobody has that slow of a machine!

#
# Test with OO model
#
{
    use Parallel::WorkUnit;
    my $wu = Parallel::WorkUnit->new();
    ok( defined($wu), "Constructer returned object" );

    pipe my $rfh, my $wfh;

    $wu->start( sub { print $wfh "TeStInG\n"; } );

    while ( my $result = <$rfh> ) {
        chomp $result;
        is( $result, 'TeStInG', "Child process 1 ran properly" );
        last;
    }

    close $rfh;
}

#
# Test without OO model
#
{
    use Parallel::WorkUnit::Procedural qw(:all);
    pipe my $rfh, my $wfh;

    start( sub { print $wfh "TeStInG\n"; } );

    while ( my $result = <$rfh> ) {
        chomp $result;
        is( $result, 'TeStInG', "Child process 2 ran properly" );
        last;
    }

    close $rfh;
}

done_testing();

