use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Common::String qw(
    LowerCaseSimpleStr
    UpperCaseSimpleStr
    LowerCaseStr
    UpperCaseStr
    NumericCode
);

is(to_UpperCaseSimpleStr('foo'), 'FOO', 'uppercase str' );
is(to_LowerCaseSimpleStr('BAR'), 'bar', 'lowercase str' );

is(to_UpperCaseStr('foo'), 'FOO', 'uppercase str' );
is(to_LowerCaseStr('BAR'), 'bar', 'lowercase str' );

is(to_NumericCode('4111-1111-1111-1111'), '4111111111111111', 'numeric code' );
is(to_NumericCode('+1 (800) 555-01-23'), '18005550123', 'numeric code' );

done_testing;
