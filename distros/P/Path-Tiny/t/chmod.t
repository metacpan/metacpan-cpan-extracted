use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

use Path::Tiny;

my $fh = path("t/data/chmod.txt")->openr;

while ( my $line = <$fh> ) {
    chomp $line;
    my ( $chmod, $orig, $expect ) = split " ", $line;
    my $got = sprintf( "%05o", Path::Tiny::_symbolic_chmod( oct($orig), $chmod ) );
    is( $got, $expect, "$orig -> $chmod -> $got" );
}

my $path = Path::Tiny->tempfile;

like(
    exception { $path->chmod("ldkakdfa") },
    qr/Invalid mode argument/,
    "Invalid mode throws exception"
);

like(
    exception { $path->chmod("sdfa=kdajfkl") },
    qr/Invalid mode clause/,
    "Invalid mode clause throws exception"
);

ok( exception { path("adljfasldfj")->chmod(0700) },
    "Nonexistent file throws exception" );

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

# vim: ts=4 sts=4 sw=4 et:
