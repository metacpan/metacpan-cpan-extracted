use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

use Path::Tiny;
use Cwd;

my $IS_WIN32 = $^O eq 'MSWin32';

my @cases = (
    [ 'foo.txt', [ '.txt',    '.png' ],    'foo' ],
    [ 'foo.png', [ '.txt',    '.png' ],    'foo' ],
    [ 'foo.txt', [ qr/\.txt/, qr/\.png/ ], 'foo' ],
    [ 'foo.png', [ qr/\.txt/, qr/\.png/ ], 'foo' ],
    [ 'foo.txt', ['.jpeg'], 'foo.txt' ],
    [ 'foo/.txt/bar.txt', [ qr/\.txt/, qr/\.png/ ], 'bar' ],
);

for my $c (@cases) {
    my ( $input, $args, $result ) = @$c;
    my $path = path($input);
    my $base = $path->basename(@$args);
    is( $base, $result, "$path -> $result" );
}

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
