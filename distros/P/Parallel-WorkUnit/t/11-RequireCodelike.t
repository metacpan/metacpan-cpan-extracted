#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2019 Joelle Maslak
# All Rights Reserved - See License
#

# This tests that async() or queue() called with non-code-refs generates
# an error.

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
my $wu = Parallel::WorkUnit->new();
ok( defined($wu), "Constructer returned object" );

like( dies { $wu->queue(1); }, qr/is not a code/, "queue() dies when passed an integer", );
like( dies { $wu->async(1); }, qr/is not a code/, "async() dies when passed an integer", );

#
# Things that should work:

ok( lives { $wu->queue( \&testfunc ); }, "queue() lives when passed an function ref", );
ok( lives { $wu->async( \&testfunc ); }, "async() lives when passed an function ref", );

ok(
    lives {
        $wu->queue( sub { return 42 * 42; } );
    },
    "queue() lives when passed an code ref",
);
ok(
    lives {
        $wu->async( sub { return 42 * 42; } );
    },
    "async() lives when passed an code ref",
);

my $codelike = Parallel::WorkUnit::Test::Overload->new();
is( $codelike->(), 42, "Object overloaded properly" );

ok( lives { $wu->queue($codelike); }, "queue() lives when passed an overloaded code-like thingy", );
ok( lives { $wu->async($codelike); }, "async() lives when passed an overloaded code-like thingy", );

$wu->waitall();

done_testing();

sub testfunc() {
    return -42;
}

package Parallel::WorkUnit::Test::Overload;

use overload '&{}' => \&execfunc;

sub new {
    my $class = shift;

    # Make things slightly trickier with an array
    return bless [], $class;
}

sub execfunc {
    return sub {
        return 42;
    };
}

1;

