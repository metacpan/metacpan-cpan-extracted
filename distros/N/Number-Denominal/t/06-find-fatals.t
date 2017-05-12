#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Number::Denominal;

#####
#####  Try out a whole ton of values and see if we die anywhere
#####

$Number::Denominal::VERSION ||= '[undef]';
diag "Testing Number::Denominal version $Number::Denominal::VERSION";
diag "...located at $INC{'Number/Denominal.pm'}";

$ENV{EXTENDED_TESTING}
    and diag q{$EXTENDED_TESTING enabled; will test 300,000 values};

local $@;
for ( $ENV{EXTENDED_TESTING}
    ? (  map $_*100, 1..3e5 )
    : ( map $_*1000, 1..1e4 )
) {
    eval { denominal( $_, \'time' ); 1; };
    $@ and BAIL_OUT "[$_]; unit shortcut. Got fatal error: $@";

    eval { denominal( $_, \'time', { precision => 1 } ); 1; };
    $@ and BAIL_OUT "[$_]; unit shortcut, precision 1. Got fatal error: $@";

    diag "So far so good at [$_]"
        if $_ % 2e6 == 0;
}

ok(1);
done_testing();