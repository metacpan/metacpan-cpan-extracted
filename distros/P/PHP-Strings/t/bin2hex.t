#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
BEGIN { use_ok 'PHP::Strings', ':bin2hex' };

# Good inputs
{
    eval { bin2hex(q{'x'} ) };
    like( $@, qr/PHP::Strings::bin2hex will not be implemented/i, "Not implemented." );
}
