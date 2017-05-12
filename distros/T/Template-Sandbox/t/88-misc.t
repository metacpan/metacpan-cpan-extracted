#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 3;

my ( $template, $syntax );

#
#  1: tersedump()
like( Template::Sandbox::_tersedump( { a => 1 } ),
    qr/^\s*\{\s+\"a\"\s+=>\s+1\s+\}\s*$/,
    '_tersedump()' );

#
#  2: tinydump()
is( Template::Sandbox::_tinydump( { a => 1 } ), "{a=>1}",
    '_tersedump()' );

#  3: cache_key()
like( Template::Sandbox->cache_key( { a => 1 } ),
    qr/^[a-zA-Z0-9]+$/,
    'cache_key()' );
