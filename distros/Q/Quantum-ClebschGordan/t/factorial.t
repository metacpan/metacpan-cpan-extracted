#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Quantum::ClebschGordan;

is( Quantum::ClebschGordan::factorial(0), 1, "0!" );
is( Quantum::ClebschGordan::factorial(1), 1, "1!" );
is( Quantum::ClebschGordan::factorial(-1), undef, "-1!" );
is( Quantum::ClebschGordan::factorial(-10), undef, "-10!" );
is( Quantum::ClebschGordan::factorial(2), 2, "2!" );
is( Quantum::ClebschGordan::factorial(3), 6, "3!" );
is( Quantum::ClebschGordan::factorial(undef), undef, "undef!" );
is( Quantum::ClebschGordan::factorial(3.5), undef, "3.5!" );
is( Quantum::ClebschGordan::factorial('foo'), undef, "foo!" );

#eof#

