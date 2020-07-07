#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2020 Joelle Maslak
# All Rights Reserved - See License
#

# This tests a bug reported by SREZIC - when the child returned with
# something Storable couldn't handle, this very ungracefully failed.

use strict;
use warnings;
use autodie;

use Carp;
use Storable;
use Test2::V0;

# Set Timeout
local $SIG{ALRM} = sub { die "timeout\n"; };
alarm 120;    # It would be nice if we did this a better way, since
              # strictly speaking, 120 seconds isn't necessarily
              # indicative of failure if running this on a VERY
              # slow machine.
              # But hopefully nobody has that slow of a machine!

# Instantiate the object
use Parallel::WorkUnit;
my $wu = Parallel::WorkUnit->new();
ok( defined($wu), "Constructer returned object" );

my $result;
SKIP: {
    skip( "Old version of storable is okay with regex", 1 )
      unless ( $^V and $^V ge v5.12.0 );

    skip( "Storable >= 3.06 is okay with regex", 1 )
      unless ( $Storable::VERSION lt 3.06 );

    $wu->async( sub { qr{xxx} }, sub { $result = shift; } );

    like(
        dies { $wu->waitall(); },
        qr/Can't store REGEXP items/,
        'Child throws a storable error for regex',
    );
}

$wu->async(
    sub {
        sub { 1; }
    },
    sub {
        $result = shift;
    }
);

like(
    dies { $wu->waitall(); },
    qr/Can't store CODE items/,
    'Child throws a storable error for code',
);

done_testing();

