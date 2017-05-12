use Test::More;
use Test::FailWarnings;
use Test::Exception;

use strict;
use warnings;

BEGIN {
    use_ok 'Regexp::CharClasses::Helper';
}

for $_ (
    '\t\t',
    '\t\t\t\t',
) {
    throws_ok { Regexp::CharClasses::Helper::fmt($_) } qr/Unknown charname/, 'malformed TSVs';
}
my @invalids = (
    '\x41',
    'U+41',
    'a!',
    '+U41',
    '!aa',
    '!a b',
    '!a\tb',
    "!a\tbeep",
    "!beep\ta",
    "!a\tbeep",
    'LATIN X',
    'beep beep',
    'beep a',
    'a beep',
    'aa',
    "a\nbeep",
    "a q\ta",
    "a\ta q",
    "a q\ta q",
    '',
);
for $_ (@invalids) {
    throws_ok { Regexp::CharClasses::Helper::fmt($_) } qr/Unknown charname/, "malformed unicode name '$_'";
}
throws_ok { Regexp::CharClasses::Helper::fmt('a', "b\tc", '11') } qr/Unknown charname/, "malformed unicode name in multiline string";

throws_ok { Regexp::CharClasses::Helper::fmt(undef) } qr/undef/i, "Checking undef handling";
throws_ok { Regexp::CharClasses::Helper::fmt('a', undef) } qr/undef/i, "Checking undef handling";


done_testing
