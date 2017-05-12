#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
BEGIN { use_ok 'PHP::Strings', ':addslashes' };

# Good inputs
{
    eval { addslashes(q{'x'} ) };
    like( $@, qr/PHP::Strings::addslashes will not be implemented/i, "Not implemented." );
}
