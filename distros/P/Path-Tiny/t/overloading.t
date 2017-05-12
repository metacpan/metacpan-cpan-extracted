use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

use Path::Tiny;

my $path = path("t/stringify.t");

is( "$path",          "t/stringify.t", "stringify via overloading" );
is( $path->stringify, "t/stringify.t", "stringify via method" );
ok( $path, "boolifies to true" );

done_testing;
#
# This file is part of Path-Tiny
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
