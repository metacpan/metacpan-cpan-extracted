#!perl -T

use strict;
use warnings;

use Test::More tests => 26;
use Struct::Path::PerlStyle qw(str2path path2str);

use lib 't';
use _common qw(roundtrip t_dump);

# unquoted utf8 for hash key doesn't supported yet =(
# https://github.com/adamkennedy/PPI/issues/168#issuecomment-180506979
eval { str2path('{кириллица}'), };
like($@, qr/Failed to parse passed path/, "can't parse unquoted utf8 hash keys");

eval { path2str([{garbage => ['a']}]) };
like($@, qr/^Unsupported hash definition \(garbage\), step #0 /);

eval { path2str([{K => 'a'}]) };
like($@, qr/^Unsupported hash keys definition, step #0 /);

eval { path2str([{K => ['a'], garbage => ['b']}]) };
like($@, qr/^Unsupported hash definition \(garbage\), step #0 /);

eval { path2str([{K => [undef]}]) };
like($@, qr/^Unsupported hash key type 'undef', step #0 /);

eval { path2str([{K => ['test',[]]}]) };
like($@, qr/^Unsupported hash key type 'ARRAY', step #0 /);

roundtrip (
    [{K => ['a']},{K => ['b']},{K => ['c']}],
    '{a}{b}{c}',
    "Explicit hash keys definition"
);

roundtrip (
    [{K => ['a']},{},{K => ['c']}],
    '{a}{}{c}',
    "Implicit hash keys definition"
);

roundtrip (
    [{K => [""]},{K => [" "]}],
    '{""}{" "}',
    "Empty string and space as hash keys"
);

# no roundtrip here - will be comma-separated
# TODO: get rid of it (deprecated since 0.72)
is_deeply(
    str2path('{a b}{e d}'),
    [{K => ['a','b']},{K => ['e','d']}],
    "Spaces as delimiters"
);

# no roundtrip here - spaces will be discarded
is_deeply(
    str2path('{ c,a, b}{e  ,d }'),
    [{K => ['c','a','b']},{K => ['e','d']}],
    "Hash path with slices and whitespace garbage"
);

roundtrip (
    [{K => ['  a b']}],
    '{"  a b"}',
    "Double quotes"
);

# no roundtrip here - double quotes used on serialization
is_deeply(
    str2path("{'  c d'}"),
    [{K => ['  c d']}],
    "Single quotes"
);

# no roundtrip here - no quotes for ASCII simple words
is_deeply(
    str2path('{\'first\',"second"}{"3rd" \'4th\'}'),
    [{K => ['first','second']},{K => ['3rd','4th']}],
    "Quotes on simple words"
);

roundtrip (
    [{K => ['b','a']},{K => ['c','d']}],
    '{b,a}{c,d}',
    "Order should be respected"
);

roundtrip (
    [{K => ['co:lo:ns','semi;colons','dashe-s','sl/as/hes']}],
    '{"co:lo:ns","semi;colons","dashe-s","sl/as/hes"}',
    "Quotes for colons"
);

roundtrip (
    [{K => ['/looks like regexp, but string/','/another/']}],
    '{"/looks like regexp, but string/","/another/"}',
    "Quotes for regexp looking strings"
);

roundtrip (
    [{K => ['"','""', "'", "''"]}],
    '{"\"","\"\"","\'","\'\'"}',
    "Quoting characters"
);

roundtrip (
    [{K => ["\t","\n","\r","\f","\b","\a","\e"]}],
    '{"\t","\n","\r","\f","\b","\a","\e"}',
    "Escape sequences"
);

# no roundtrip here - double quotes used on serialization
is_deeply(
    str2path('{\'\t\',\'\n\',\'\r\',\'\f\',\'\b\',\'\a\',\'\e\'}'),
    [{K => ['\t','\n','\r','\f','\b','\a','\e']}],
    "Do not unescape when single quoted"
);

roundtrip (
    [{K => [qw# | ( ) [ { ^ $ * + ? . #]}],
    '{"|","(",")","[","{","^","$","*","+","?","."}',
    "Pattern metacharacters"
);

roundtrip (
    [{K => ['кириллица']}],
    '{"кириллица"}',
    "Non ASCII characters must be quoted even it's a bareword"
);

roundtrip (
    [{K => [0, 42, '43', '42.0', 42.1, -41, -41.3, '-42.3']}],
    '{0,42,43,42.0,42.1,-41,-41.3,-42.3}',
    "Numbers as hash keys" # must remain unquoted on serialization
);

SKIP: {
    skip 'mswin32 stringify such numbers a bit differently', 1
        if ($^O =~ /MSWin32/i);

    roundtrip (
        [{K => ['1e+42', 1e43, 1e3, 1e-05]}],
        '{1e+42,1e+43,1000,1e-05}',
        'Scientific notation for a floating-point numbers'
    );
}

is_deeply(
    str2path('{01.0}'), # bug?? (PPI treats this as two things: octal and double)
    [{K => ['01','.0']}],
);

is_deeply(
    str2path('{01}{"01"}{127.0.0.1}{  1}{undef}'),
    [{K => ['01']},{K => ['01']},{K => ['127.0.0.1']},{K => ['1']},{K => ['undef']}],
    "Undecided %)"
);

