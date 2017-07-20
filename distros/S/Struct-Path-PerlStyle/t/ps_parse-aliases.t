#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(ps_parse);
use Test::More tests => 6;

my $aliases = {
    A01 => '{first}',
    A02 => '[2]',
    A03 => '$A02{third}',
    A04 => '$A03[4]',
};

eval { ps_parse('$UNEXISTED_ALIAS') };
like($@, qr/^Unknown alias 'UNEXISTED_ALIAS'/);

eval { ps_parse('@UNSUPPORTED_SIGIL') };
like($@, qr/^Unsupported thing '\@UNSUPPORTED_SIGIL' in the path, step #0 /);

eval { ps_parse('$A01.$A02', {aliases => $aliases}) };
like($@, qr/^Unsupported thing '.' in the path/, "no operators suported for aliases");

is_deeply(
    ps_parse('$A01', {aliases => $aliases}),
    [{keys => ["first"]}],
    "single alias"
);

is_deeply(
    ps_parse('$A01$A04', {aliases => $aliases}),
    [{keys => ["first"]},[2],{keys => ["third"]},[4]],
    "recirsive aliases"
);

is_deeply(
    ps_parse('{first}$A03[4]', {aliases => $aliases}),
    [{keys => ["first"]},[2],{keys => ["third"]},[4]],
    "aliases combined with usual steps"
);

