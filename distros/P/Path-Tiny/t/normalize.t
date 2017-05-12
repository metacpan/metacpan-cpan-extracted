use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use TestUtils qw/exception/;

use Path::Tiny;

my @cases = (
#<<<
    [ '.'   => '.'  ],
    [ './'  => '.'  ],
    [ '/'   => '/'  ],
    [ '/.'  => '/'  ],
    [ '..'  => '..' ],
    [ '/..'  => '/' ],
    [ '../'  => '..' ],
    [ '../..'  => '../..' ],
    [ '/./'  => '/' ],
    [ '/foo/'  => '/foo' ],
    [ 'foo/'  => 'foo' ],
    [ './foo'  => 'foo' ],
    [ 'foo/.'  => 'foo' ],
#>>>
);

for my $c (@cases) {
    my ( $in, $out ) = @$c;
    my $label = defined($in) ? $in : "undef";
    $label = "empty" unless length $label;
    is( path($in)->stringify, $out, sprintf( "%5s -> %-5s", $label, $out ) );
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
