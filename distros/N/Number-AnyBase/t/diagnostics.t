#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( eval 'use Test::Fatal; 1' ) {
        plan skip_all => "Test::Fatal required to run these tests"
    }
}

plan tests => 3;

use constant {
    SINGLE_SYMBOL_ERR_MESS_RE => qr/must have at least two symbols/,
    LONG_SYMBOLS_ERR_MESS_RE  => qr/cannot be more than one character long/
};

use Number::AnyBase;

like(
    exception { Number::AnyBase->new('a') },
    SINGLE_SYMBOL_ERR_MESS_RE,
    'Single symbol alphabet'
);

like(
    exception { Number::AnyBase->new(qw/z z z z/) },
    SINGLE_SYMBOL_ERR_MESS_RE,
    'Single symbol alphabet repeated'
);

like(
    exception { Number::AnyBase->new(qw/z z z aa/) },
    LONG_SYMBOLS_ERR_MESS_RE,
    'Single symbol alphabet repeated'
);
