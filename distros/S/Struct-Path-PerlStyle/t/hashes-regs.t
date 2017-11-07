#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 18;
use Struct::Path::PerlStyle qw(ps_parse ps_serialize);

use lib 't';
use _common qw(roundtrip);

eval { ps_parse('{s/patt/subst/g}') };
like($@, qr|^Unsupported thing 's/patt/subst/g' for hash key, step #0 |);

SKIP: {
    skip "Old perls (or Safe.pm?) silently dies on this regexps", 3
        unless ($] >= 5.014);

    eval { ps_parse('{word}{qr/(?{ exit 123 })/}') };
    like($@, qr|^Step #1: failed to evaluate regexp: 'exit' trapped |);

    eval { ps_parse('{qr/(?{ garbage })/}') };
    like($@, qr|^Step #0: failed to evaluate regexp: 'subroutine dereference' trapped |);

    eval { ps_parse('{qr/(?{ `echo >&2 WHOAA` })/}') };
    like($@, qr|^Step #0: failed to evaluate regexp: 'pushmark' trapped |);
}

eval { ps_serialize([{regs => 1}]) };
like($@, qr/^Unsupported hash regs definition, step #0 /);

eval { ps_serialize([{regs => [1]}]) };
like($@, qr/^Regexp expected for regs item, step #0 /);

roundtrip (
    [{regs => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    '{/pat/,/pat/i,/pat/m,/pat/s,/pat/x}',
    '//'
);

is_deeply(
    ps_parse('{m/pat/,m!pat!i,m|pat|m,m#pat#s,m{pat}x}'),
    [{regs => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    "m//"
);

is_deeply(
    ps_parse('{qr/pat/,qr!pat!i,qr|pat|m,qr#pat#s,qr{pat}x}'),
    [{regs => [qr/pat/,qr/pat/i,qr/pat/m,qr/pat/s,qr/pat/x]}],
    "qr//"
);

roundtrip (
    [{regs => [qr/^Lonesome regexp$/mi]}],
    '{/^Lonesome regexp$/mi}',
    'Lonesome regexp'
);

roundtrip (
    [{keys => ['Mixed', 'with'], regs => [qr/regular keys/]}],
    '{Mixed,with,/regular keys/}',
    'Regs mixed with keys'
);

roundtrip (
    [{regs => [qr//,qr//msix]}],
    '{//,//msix}',
    'Empty pattern'
);

roundtrip (
    [{regs => [qr/^Regular\/\/Slashes/]}],
    '{/^Regular\/\/Slashes/}',
    'Regular slashes'
);

roundtrip (
    [{regs => [qr/^TwoBack\\Slashes/]}],
    '{/^TwoBack\\\\Slashes/}',
    'Back slashes'
);

roundtrip (
    [{regs => [qr/Character\b\B\d\D\s\S\w\WClasses/]}],
    '{/Character\b\B\d\D\s\S\w\WClasses/}',
    'Character classes'
);

roundtrip (
    [{regs => [qr/Escape\t\n\r\f\b\a\eSequences/]}],
    '{/Escape\t\n\r\f\b\a\eSequences/}',
    'Escape sequences'
);

roundtrip (
    [{regs => [qr/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\033Sequences2/]}],
    '{/Escape\x{263A}|\x1b|\N{U+263D}|\c[|\033Sequences2/' .
        ($] >= 5.014 ? 'u' : '') . '}',
    'Escape sequences2'
);

roundtrip (
    [{regs => [qr#^([^\?]{1,5}|.+|\\?|)*$#]}],
    '{/^([^\?]{1,5}|.+|\\\\?|)*$/}',
    'Metacharacters'
);

