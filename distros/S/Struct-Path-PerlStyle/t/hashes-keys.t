#!perl -T

use strict;
use warnings;

use Test::More tests => 26;
use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

use lib 't';
use _common qw(roundtrip t_dump);

# unquoted utf8 for hash key doesn't supported yet =(
# https://github.com/adamkennedy/PPI/issues/168#issuecomment-180506979
eval { ps_parse('{кириллица}'), };
like($@, qr/Failed to parse passed path/, "can't parse unquoted utf8 hash keys");

eval { ps_serialize([{garbage => ['a']}]) };
like($@, qr/^Unsupported hash definition \(garbage\), step #0 /);

eval { ps_serialize([{keys => 'a'}]) };
like($@, qr/^Unsupported hash keys definition, step #0 /);

eval { ps_serialize([{keys => ['a'], garbage => ['b']}]) };
like($@, qr/^Unsupported hash definition \(garbage\), step #0 /);

eval { ps_serialize([{keys => [undef]}]) };
like($@, qr/^Unsupported hash key type 'undef', step #0 /);

eval { ps_serialize([{keys => ['test',[]]}]) };
like($@, qr/^Unsupported hash key type 'ARRAY', step #0 /);

roundtrip (
    [{keys => ['a']},{keys => ['b']},{keys => ['c']}],
    '{a}{b}{c}',
    "Explicit hash keys definition"
);

roundtrip (
    [{keys => ['a']},{},{keys => ['c']}],
    '{a}{}{c}',
    "Implicit hash keys definition"
);

roundtrip (
    [{keys => [""]},{keys => [" "]}],
    '{""}{" "}',
    "Empty string and space as hash keys"
);

# no roundtrip here - will be comma-separated
# TODO: get rid of it (deprecated since 0.72)
is_deeply(
    ps_parse('{a b}{e d}'),
    [{keys => ['a','b']},{keys => ['e','d']}],
    "Spaces as delimiters"
);

# no roundtrip here - spaces will be discarded
is_deeply(
    ps_parse('{ c,a, b}{e  ,d }'),
    [{keys => ['c','a','b']},{keys => ['e','d']}],
    "Hash path with slices and whitespace garbage"
);

roundtrip (
    [{keys => ['  a b']}],
    '{"  a b"}',
    "Double quotes"
);

# no roundtrip here - double quotes used on serialization
is_deeply(
    ps_parse("{'  c d'}"),
    [{keys => ['  c d']}],
    "Single quotes"
);

# no roundtrip here - no quotes for ASCII simple words
is_deeply(
    ps_parse('{\'first\',"second"}{"3rd" \'4th\'}'),
    [{keys => ['first','second']},{keys => ['3rd','4th']}],
    "Quotes on simple words"
);

roundtrip (
    [{keys => ['b','a']},{keys => ['c','d']}],
    '{b,a}{c,d}',
    "Order should be respected"
);

roundtrip (
    [{keys => ['co:lo:ns','semi;colons','dashe-s','sl/as/hes']}],
    '{"co:lo:ns","semi;colons","dashe-s","sl/as/hes"}',
    "Quotes for colons"
);

roundtrip (
    [{keys => ['/looks like regexp, but string/','/another/']}],
    '{"/looks like regexp, but string/","/another/"}',
    "Quotes for regexp looking strings"
);

roundtrip (
    [{keys => ['"','""', "'", "''"]}],
    '{"\"","\"\"","\'","\'\'"}',
    "Quoting characters"
);

roundtrip (
    [{keys => ["\t","\n","\r","\f","\b","\a","\e"]}],
    '{"\t","\n","\r","\f","\b","\a","\e"}',
    "Escape sequences"
);

# no roundtrip here - double quotes used on serialization
is_deeply(
    ps_parse('{\'\t\',\'\n\',\'\r\',\'\f\',\'\b\',\'\a\',\'\e\'}'),
    [{keys => ['\t','\n','\r','\f','\b','\a','\e']}],
    "Do not unescape when single quoted"
);

roundtrip (
    [{keys => [qw# | ( ) [ { ^ $ * + ? . #]}],
    '{"|","(",")","[","{","^","$","*","+","?","."}',
    "Pattern metacharacters"
);

roundtrip (
    [{keys => ['кириллица']}],
    '{"кириллица"}',
    "Non ASCII characters must be quoted even it's a bareword"
);

roundtrip (
    [{keys => [0, 42, '43', '42.0', 42.1, -41, -41.3, '-42.3']}],
    '{0,42,43,42.0,42.1,-41,-41.3,-42.3}',
    "Numbers as hash keys" # must remain unquoted on serialization
);

SKIP: {
    skip 'mswin32 stringify such numbers a bit differently', 1
        if ($^O =~ /MSWin32/i);

    roundtrip (
        [{keys => ['1e+42', 1e43, 1e3, 1e-05]}],
        '{1e+42,1e+43,1000,1e-05}',
        'Scientific notation for a floating-point numbers'
    );
}

is_deeply(
    ps_parse('{01.0}'), # bug?? (PPI treats this as twi things: octal and double)
    [{keys => ['01','.0']}],
);

is_deeply(
    ps_parse('{01}{"01"}{127.0.0.1}{  1}{undef}'),
    [{keys => ['01']},{keys => ['01']},{keys => ['127.0.0.1']},{keys => ['1']},{keys => ['undef']}],
    "Undecided %)"
);

