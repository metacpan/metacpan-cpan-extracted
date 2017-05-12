#!/usr/bin/perl

use Test::More tests => 3;
BEGIN { use_ok('POE::Wheel::UDP') };

eval { POE::Wheel::UDP->allocate_wheel_id };
like( $@, qr/Undefined subroutine/i, "allocate_wheel_id shouldn't inherit" );

eval { POE::Wheel::UDP->free_wheel_id };
like( $@, qr/Undefined subroutine/i, "free_wheel_id shouldn't inherit" );
