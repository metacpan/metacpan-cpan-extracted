#!perl -T

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Struct::Diff qw(diff);
use Test::More;

use lib "t";
use _common;

# Data::Dumper as serializer (Storable fails on regexps)
$Struct::Diff::FREEZER = sub {
    local $Data::Dumper::Deparse    = 1;
    local $Data::Dumper::Indent     = 0;
    local $Data::Dumper::Pair       = '';
    local $Data::Dumper::Sortkeys   = 1;
    local $Data::Dumper::Terse      = 1;

    return Dumper @_;
};

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
    {
        a       => [ qr/bar/m ],
        b       => [ qr/foo/m ],
        name    => 'nested_different_regexps',
        diff    => {D => [{N => qr/foo/m,O => qr/bar/m}]},
    },
    {
        a       => [ qr/foo/i ],
        b       => [ qr/foo/i ],
        name    => 'nested_equal_regexps',
        diff    => {U => [qr/foo/i]},
    },
);

map { $_->{to_json} = 0 } @TESTS;

run_batch_tests(@TESTS);

is_deeply(
    diff(
        { one => qr/foo/i },
        { one => qr/bar/i },
        freezer => sub { Dumper $_[0] }
    ),
    {D => {one => {N => qr/bar/i,O => qr/foo/i}}},
    "freezer opt test"
);

done_testing();
