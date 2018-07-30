#!perl -T

use strict;
use warnings;
use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 6;

$Struct::Path::PerlStyle::ALIASES = {
    Global0 => '{foo}',
};

my $aliases = {
    Local1 => '{first}',
    Local2 => '[2]',
    Local3 => '<Local2>{third}',
    Local4 => '<Local3>[4]',
};

eval { str2path('<UNEXISTED_ALIAS>') };
like($@, qr/^Unknown alias 'UNEXISTED_ALIAS'/);

eval { str2path('<Global0>', {aliases => $aliases}) };
like($@, qr/^Unknown alias 'Global0'/);

is_deeply(
    str2path('<Global0>'),
    [{K => ["foo"]}],
    "single alias"
);

is_deeply(
    str2path('<Local1>', {aliases => $aliases}),
    [{K => ["first"]}],
    "single alias"
);

is_deeply(
    str2path('<Local1><Local4>', {aliases => $aliases}),
    [{K => ["first"]},[2],{K => ["third"]},[4]],
    "recirsive aliases"
);

is_deeply(
    str2path('{first}<Local3>[4]', {aliases => $aliases}),
    [{K => ["first"]},[2],{K => ["third"]},[4]],
    "aliases combined with usual steps"
);

