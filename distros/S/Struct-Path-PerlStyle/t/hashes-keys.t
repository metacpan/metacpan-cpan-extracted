#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 32;
use Struct::Path::PerlStyle qw(str2path path2str);

use lib 't';
use _common qw(roundtrip t_dump);

eval { path2str([{garbage => ['a']}]) };
like($@, qr/^Unsupported hash definition \(unknown keys\), step #0 /);

eval { path2str([{K => 'a'}]) };
like($@, qr/^Unsupported hash keys definition, step #0 /);

eval { path2str([{K => ['a'], garbage => ['b']}]) };
like($@, qr/^Unsupported hash definition \(extra keys\), step #0 /);

eval { path2str([{K => [undef]}]) };
like($@, qr/^Unsupported hash key type 'undef', step #0 /);

eval { path2str([{K => ['test',[]]}]) };
like($@, qr/^Unsupported hash key type 'ARRAY', step #0 /);

eval { str2path('{,a}') };
like($@, qr/^Unsupported key ',a', step #0 /, 'Leading comma');

eval { str2path('{a,}') };
like($@, qr/^Trailing delimiter at step #0 /, 'Trailing comma');

eval { str2path('{"a""b"}') };
like($@, qr/^Delimiter expected before '"b"', step #0 /, 'Delimiter missed, double quoted key');

eval { str2path('{"a" "b"}') };
like($@, qr/^Delimiter expected before '"b"', step #0 /, 'Space for delimiter');

eval { str2path("{'a''b'}") };
like($@, qr/^Delimiter expected before ''b'', step #0 /, 'Delimiter missed, single quoted key');

TODO: {
    local $TODO = "crap";
eval { str2path('{a+b}') };
like($@, qr/^Unsupported thing .* for hash key, step /, "garbage in hash keys definition");
}

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
    [{K => [""]},{K => [" "]},{K => ["0"]}],
    '{""}{" "}{0}',
    "Empty string, space and bare zero as single hash key"
);

is_deeply(
    str2path('{ c,a, b}{e  ,d }'),
    [{K => ['c','a','b']},{K => ['e','d']}],
    "Unquoted leading and trailing spaces should be discarded"
);

roundtrip (
    [{K => [' c','a',' b']},{K => ['e  ','d ']}],
    '{" c",a," b"}{"e  ","d "}',
    "Qouted leading and trailing spaces should be preserved"
);

roundtrip (
    [{K => ['  a b,c']}],
    '{"  a b,c"}',
    "Double quotes"
);

# no roundtrip here - double quotes used on serialization
is_deeply(
    str2path("{'  c d,e'}"),
    [{K => ['  c d,e']}],
    "Single quotes"
);

# no roundtrip here - no quotes for barewords
is_deeply(
    str2path('{\'first\',"second"}{"3rd",\'4th\'}'),
    [{K => ['first','second']},{K => ['3rd','4th']}],
    "Quotes on simple words"
);

roundtrip (
    [{K => ['b','a']},{K => ['c','d']}],
    '{b,a}{c,d}',
    "Order should be respected"
);

roundtrip (
    [{K => ['+','-','.','_']}],
    '{+,-,.,_}',
    "Bareword hash keys extra"
);

roundtrip (
    [{K => ['co:lo:ns','semi;colons','sl/as/hes']}],
    '{"co:lo:ns","semi;colons","sl/as/hes"}',
    "Quotes for punct characters"
);

roundtrip (
    [{K => ['/looks like regexp, but string/','m/another/']}],
    '{"/looks like regexp, but string/","m/another/"}',
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
    "Do not interpolate single quoted strings"
);

roundtrip (
    [{K => [qw# | ( ) [ { ^ $ * + ? . #]}],
    '{"|","(",")","[","{","^","$","*",+,"?",.}',
    "Pattern metacharacters"
);

roundtrip (
    [{K => ['кириллица', 'два слова']}],
    '{кириллица,"два слова"}',
    "Non ASCII characters"
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
    str2path('{01.0}'),
    [{K => ['01.0']}],
);

is_deeply(
    str2path('{01}{"01"}{127.0.0.1}{"2001:db8:1::/64"}{  1}{0_1}{undef}'),
    [{K => ['01']},{K => ['01']},{K => ['127.0.0.1']},{K => ['2001:db8:1::/64']},{K => ['1']},{K => ['0_1']},{K => ['undef']}],
    "Undecided %)"
);

