#!/usr/bin/perl

# specifically *don't*
#   use v5.18;
#   use warnings;

use Test2::V0 -no_strict => 1, -no_warnings => 1;

use Object::Pad 0.800;

my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, $_[0] }; }

class X {}

like( $warnings[0], qr/^class keyword enabled 'use strict' but this will be removed in a later version at /,
   'class keyword emits warning about use strict' );
like( $warnings[1], qr/^class keyword enabled 'use warnings' but this will be removed in a later version at /,
   'class keyword emits warning about use warnings' );

done_testing;
