#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 24;
use Struct::Path::PerlStyle qw(str2path path2str);

use lib 't';
use _common qw(roundtrip);

eval { str2path('{s/patt/subst/g}') };
like($@, qr|^Unsupported key 's/patt/subst/g', step #0 |);

eval { str2path('{qr/pat/}') };
like($@, qr|^Unsupported key 'qr/pat/', step #0 |);

eval { str2path('{/a//}') };
like($@, qr|^Delimiter expected before '/', step #0 |, "regexp and one more slash");

eval { str2path('{/a//b/}') };
like($@, qr|^Delimiter expected before '/b/', step #0 |, "two regs, no delimiter");

eval { str2path('{/a/"b"}') };
like($@, qr|^Delimiter expected before '"b"', step #0 |, "reg and quoted string, no delimiter");

eval { str2path('{,/a/}') };
like($@, qr|^Unsupported key ',/a/', step #0 |, "Leading delimiter");

eval { str2path('{/a/,}') };
like($@, qr|^Trailing delimiter at step #0 |, "Trailing delimiter");

eval { str2path('{/pat/u}') };
like($@, qr|^Delimiter expected before 'u', step #0 |, "for Perl's internal use (c) perlre");

SKIP: {
    skip "Old perls (or Safe.pm?) silently dies on this regexps", 3
        unless ($] >= 5.014);

    eval { str2path('{word}{/(?{ exit 123 })/}') };
    like($@, qr|^Step #1 Eval-group not allowed |);

    eval { str2path('{/(?{ garbage })/}') };
    like($@, qr|^Step #0 Eval-group not allowed |);

    eval { str2path('{/(?{ `echo >&2 WHOAA` })/}') };
    like($@, qr|^Step #0 Eval-group not allowed |);
}

eval { path2str([{R => 1}]) };
like($@, qr/^Unsupported hash regexps definition, step #0 /);

eval { path2str([{R => [1]}]) };
like($@, qr/^Regexp expected for regexps item, step #0 /);

roundtrip (
    [{R => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    '{/pat/,/pat/i,/pat/m,/pat/s,/pat/x}',
    '//'
);

is_deeply(
    str2path('{m/pat/,m!pat!i,m|pat|m,m#pat#s,m{pat}x,m(pat)i,m[pat]i,m<pat>i,m"pat"i,m\'pat\'i}'),
    [{R => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x,qr/pat/i,qr/pat/i,qr/pat/i,qr/pat/i,qr/pat/i]}],
    "m//"
);

roundtrip (
    [{R => [qr/^Lonesome regexp$/mi]}],
    '{/^Lonesome regexp$/mi}',
    'Lonesome regexp'
);

roundtrip (
    [{K => ['Mixed', 'with'], R => [qr/regular keys/]}],
    '{Mixed,with,/regular keys/}',
    'Regexps mixed with keys'
);

roundtrip (
    [{R => [qr//,qr//msix]}],
    '{//,//msix}',
    'Empty pattern'
);

roundtrip (
    [{R => [qr|^Regular\/\/Slashes|]}],
    '{/^Regular\/\/Slashes/}',
    'Regular slashes'
);

roundtrip (
    [{R => [qr/^TwoBack\\Slashes/]}],
    '{/^TwoBack\\\\Slashes/}',
    'Back slashes'
);

roundtrip (
    [{R => [qr/Character\b\B\d\D\s\S\w\WClasses/]}],
    '{/Character\b\B\d\D\s\S\w\WClasses/}',
    'Character classes'
);

roundtrip (
    [{R => [qr/Escape\t\n\r\f\b\a\eSequences/]}],
    '{/Escape\t\n\r\f\b\a\eSequences/}',
    'Escape sequences'
);

roundtrip (
    [{R => [qr/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\033Sequences2/]}],
    '{/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\033Sequences2/}',
    'Escape sequences2'
);

roundtrip (
    [{R => [qr#^([^\?]{1,5}|.+|\\?|)*$#]}],
    '{/^([^\?]{1,5}|.+|\\\\?|)*$/}',
    'Metacharacters'
);

