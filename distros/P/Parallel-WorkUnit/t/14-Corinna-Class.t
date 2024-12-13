#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2024 Joelle Maslak
# All Rights Reserved - See License
#

# This tests that if a OBJECT type is returned, it is handled
# gracefully.

use strict;
use warnings;
use autodie;

use Carp;
use feature ();
use Test2::V0 "!warnings";

# Allow compilation even if Corina is not part of the Perl
# Inspired by Feature::Compat::Class by Paul Evans.
BEGIN {
    if ($^V and $^V ge v5.38.0) {
        feature->import(qw(class));
        warnings->unimport(qw(experimental::class));
    } else {
        require Object::Pad;
        Object::Pad->import(qw(class method field),
            ':experimental(init_expr)',
            ':config(only_field_attrs=param)');
    }
};

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

class foobar {
    field $x : param;
    method baz { return 1 }
}

my $x = foobar->new( x => 1 );

my $result;
SKIP: {
    skip( "Old version of Perl doesn't have Corrina", 1 )
      unless ( $^V and $^V ge v5.38.0 );

    $wu->async( sub { $x }, sub { $result = shift; } );

    like(
        dies { $wu->waitall(); },
        qr/Can't store OBJECT items/,
        'Child throws a storable error for Corinna class objects',
    );
}

class baz {
    field $x : param;
    method x { return $x }
    method FREEZE { return $x }
    sub THAW {
        my ($class, $data) = @_;
        $class->new( x => $data );
    }
}

$x = baz->new( x => 3 );
$wu->async(sub { return $x }, sub { $result = shift; } );
$x = undef;

ok( lives { $wu->waitall(); }, "Can store a class object with FREEZE" );
is($result->x, 3, "Object properly created");

done_testing();

