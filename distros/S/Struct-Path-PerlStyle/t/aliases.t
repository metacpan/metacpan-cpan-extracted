#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 6;

my $aliases = {
    A01 => '{first}',
    A02 => '[2]',
    A03 => '$A02{third}',
    A04 => '$A03[4]',
};

eval { str2path('$UNEXISTED_ALIAS') };
like($@, qr/^Unknown alias 'UNEXISTED_ALIAS'/);

eval { str2path('@UNSUPPORTED_SIGIL') };
like($@, qr/^Unsupported thing '\@UNSUPPORTED_SIGIL' in the path, step #0 /);

eval { str2path('$A01.$A02', {aliases => $aliases}) };
like($@, qr/^Unsupported thing '.' in the path/, "no operators suported for aliases");

is_deeply(
    str2path('$A01', {aliases => $aliases}),
    [{K => ["first"]}],
    "single alias"
);

is_deeply(
    str2path('$A01$A04', {aliases => $aliases}),
    [{K => ["first"]},[2],{K => ["third"]},[4]],
    "recirsive aliases"
);

is_deeply(
    str2path('{first}$A03[4]', {aliases => $aliases}),
    [{K => ["first"]},[2],{K => ["third"]},[4]],
    "aliases combined with usual steps"
);

