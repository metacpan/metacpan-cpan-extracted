#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my $re_ref = qr/foo/msix;
my @TESTS = (
    {
        a       => $re_ref,
        b       => $re_ref,
        name    => 'equal_by_ref_regexps',
        diff    => {U => $re_ref},
    },
    {
        a       => $re_ref,
        b       => qr/foo/msix,
        name    => 'equal_by_data_regexps',
        diff    => {U => $re_ref},
    },
    {
        a       => $re_ref,
        b       => qr/foo/msix,
        name    => 'equal_by_data_regexps_noU',
        diff    => {},
        opts    => {noU => 1},
    },
    {
        a       => $re_ref,
        b       => qr/foo/m,
        name    => 'different_by_mods_regexps',
        diff    => {N => qr/foo/m,O => $re_ref},
    },
    {
        a       => $re_ref,
        b       => qr/bar/msix,
        name    => 'different_by_pattern_regexp',
        diff    => {N => qr/bar/msix,O => $re_ref},
    },
    {
        a       => $re_ref,
        b       => qr/bar/msix,
        name    => 'different_by_pattern_regexp_noN',
        diff    => {O => $re_ref},
        opts    => {noN => 1},
    },
    {
        a       => $re_ref,
        b       => qr/bar/msix,
        name    => 'different_by_pattern_regexp_noO',
        diff    => {N => qr/bar/msix},
        opts    => {noO => 1},
    },
);

map { $_->{to_json} = 0 } @TESTS;

run_batch_tests(@TESTS);

done_testing();
