#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 18;
use Struct::Path::PerlStyle qw(str2path path2str);

use lib 't';
use _common qw(roundtrip);

eval { str2path('{s/patt/subst/g}') };
like($@, qr|^Unsupported thing 's/patt/subst/g' for hash key, step #0 |);

SKIP: {
    skip "Old perls (or Safe.pm?) silently dies on this regexps", 3
        unless ($] >= 5.014);

    eval { str2path('{word}{qr/(?{ exit 123 })/}') };
    like($@, qr|^Step #1: failed to evaluate regexp: 'exit' trapped |);

    eval { str2path('{qr/(?{ garbage })/}') };
    like($@, qr|^Step #0: failed to evaluate regexp: 'subroutine dereference' trapped |);

    eval { str2path('{qr/(?{ `echo >&2 WHOAA` })/}') };
    like($@, qr|^Step #0: failed to evaluate regexp: 'pushmark' trapped |);
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
    str2path('{m/pat/,m!pat!i,m|pat|m,m#pat#s,m{pat}x}'),
    [{R => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    "m//"
);

is_deeply(
    str2path('{qr/pat/,qr!pat!i,qr|pat|m,qr#pat#s,qr{pat}x}'),
    [{R => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    "qr//"
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
    [{R => [qr/^Regular\/\/Slashes/]}],
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
    '{/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\033Sequences2/' .
        ($] >= 5.014 ? 'u' : '') . '}',
    'Escape sequences2'
);

roundtrip (
    [{R => [qr#^([^\?]{1,5}|.+|\\?|)*$#]}],
    '{/^([^\?]{1,5}|.+|\\\\?|)*$/}',
    'Metacharacters'
);

