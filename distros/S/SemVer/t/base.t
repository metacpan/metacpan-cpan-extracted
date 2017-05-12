#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 568;
#use Test::More 'no_plan';

my $CLASS;
BEGIN {
    $CLASS = 'SemVer';
    use_ok $CLASS or die;
}

diag 'Testing with version v', version->VERSION;
can_ok $CLASS, qw(
    new
    declare
    parse
    normal
    numify
    is_alpha
    is_qv
    vcmp
);

# Try the basics.
isa_ok my $version = $CLASS->new('0.1.0'), $CLASS, 'An instance';
isa_ok $SemVer::VERSION, $CLASS, q{SemVer's own $VERSION};
my $is_vpp = !!grep { $_ eq 'version::vpp' } @version::ISA;

for my $v (qw(
    1.2.2
    0.2.2
    1.2.2
    0.0.0
    0.1.999
    9999.9999999.823823
    1.0.0-beta1
    1.0.0-beta2
    1.0.0
    0.0.0-rc1
    v1.2.2
    999993333.0.0
)) {
    isa_ok my $semver =$CLASS->new($v), $CLASS, "new($v)";
    my $str = $v =~ /^v/ ? substr $v, 1 : $v;
    is "$semver", $str, qq{$v should stringify to "$str"};
    $str =~ s/(\d)([a-z].+)$/$1-$2/;
    is $semver->normal, $str, qq{$v should normalize to "$str"};

    SKIP: {
        skip 'Boolean comparison broken with version::vpp', 1, $is_vpp;
        if ($v =~ /0\.0\.0/) {
            ok !$semver, "$v should be false";
        } else {
            ok !!$semver, "$v should be true";
        }
    }

    ok $semver->is_qv, "$v should be dotted-decimal";

    my $is_alpha = $semver->is_alpha;
    if ($v =~ /[.]\d+-?[a-z]/) {
        ok $is_alpha, "$v should be alpha";
    } else {
        ok !$is_alpha, "$v should not be alpha";
    }
}

local $@;
eval { $CLASS->new('') };
ok $@, 'Empty string should be an invalid version';

for my $bv (qw(
    1.2
    0
    0.0
    1.2b
    1.b
    1.04.0
    1.65.r2
)) {
    local $@;
    eval { $CLASS->new($bv) };
    like $@, qr{Invalid semantic version string format: "$bv"},
        qq{"$bv" should be an invalid semver};
}

# Try a vstring.
isa_ok $version = $CLASS->new(v2.3.2), $CLASS, 'vstring version';
is $version->stringify, 'v2.3.2', 'vestring should stringify with "v"';
is $version->normal, '2.3.2', 'vstring should normalize without "v"';

# Try a shorter vstring.
my $no_2digitvst = $] < 5.10 && version->VERSION < 0.9910;
SKIP: {
    skip 'Two-integer vstrings weak on Perl 5.8', 3 if $no_2digitvst;
    isa_ok $version = $CLASS->new(v2.3), $CLASS, 'vstring version';
    is $version->stringify, 'v2.3', 'short vestring should stringify with "v"';
    is $version->normal, '2.3.0', 'short vstring should normalize without required 0';
}

# Try another SemVer.
isa_ok my $cloned = $CLASS->new($version), $CLASS, 'Cloned SemVer';
is $cloned->stringify, $version->stringify, 'Cloned stringify like original';
is $cloned->normal, $version->normal, 'Cloned should normalize like original';

# Try a SemVer with alpha.
isa_ok $version = $CLASS->new('2.3.2-b1'), $CLASS, 'new version';
isa_ok $cloned = $CLASS->new($version), $CLASS, 'Second cloned SemVer';
is $cloned->stringify, $version->stringify, 'Second cloned stringify like original';
is $cloned->normal, $version->normal, 'Second cloned should normalize like original';

# Numify should die
local $@;
eval { $version->numify };
like $@, qr{Semantic versions cannot be numified},
    'Should get error from numify()';

# Now do some comparisons. Start with equivalents.
for my $spec (
    [ '1.2.2',        '1.2.2' ],
    [ '1.2.23',       '1.2.23' ],
    [ '0.0.0',        '0.0.0' ],
    [ '999.888.7777', '999.888.7777' ],
    [ '0.1.2-beta3',  '0.1.2-beta3' ],
    [ '1.0.0-rc-1',   '1.0.0-RC-1' ],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    is $l->vcmp($r), 0, "$l->vcmp($r) == 0";
    is $l <=> $r, 0, "$l <=> $r == 0";
    is $r <=> $l, 0, "$r <=> $l == 0";
    cmp_ok $l, '==', $r, "$l == $r";
    cmp_ok $l, '==', $r, "$l == $r";
    cmp_ok $l, '<=', $r, "$l <= $r";
    cmp_ok $l, '>=', $r, "$l >= $r";
    is $l cmp $r, 0, "$l cmp $r == 0";
    is $r cmp $l, 0, "$r cmp $l == 0";
    cmp_ok $l, 'eq', $r, "$l eq $r";
    cmp_ok $l, 'eq', $r, "$l eq $r";
    cmp_ok $l, 'le', $r, "$l le $r";
    cmp_ok $l, 'ge', $r, "$l ge $r";
}

# Test not equal.
for my $spec (
    ['1.2.2',   '1.2.3'],
    ['0.0.1',   '1.0.0'],
    ['1.0.1',   '1.1.0'],
    ['1.1.1',   '1.1.0'],
    ['1.2.3-b', '1.2.3'],
    ['1.2.3',   '1.2.3-b'],
    ['1.2.3-a', '1.2.3-b'],
    ['1.2.3-aaaaaaa1', '1.2.3-aaaaaaa2'],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    cmp_ok $l->vcmp($r), '!=', 0, "$l->vcmp($r) != 0";
    cmp_ok $l, '!=', $r, "$l != $r";
    cmp_ok $l, 'ne', $r, "$l ne $r";
}

# Test >, >=, <, and <=.
for my $spec (
    ['2.2.2',      '1.1.1'],
    ['2.2.2',      '2.1.1'],
    ['2.2.2',      '2.2.1'],
    ['2.2.2-b',    '2.2.1'],
    ['2.2.2',      '2.2.2-b'],
    ['2.2.2-c',    '2.2.2-b'],
    ['2.2.2-rc-2', '2.2.2-RC-1'],
    ['0.9.10',     '0.9.9'],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    cmp_ok $l->vcmp($r), '>', 0, "$l->vcmp($r) > 0";
    cmp_ok $r->vcmp($l), '<', 0, "$r->vcmp($l) < 0";
    cmp_ok $l, '>',  $r, "$l > $r";
    cmp_ok $l, '>=', $r, "$l >= $r";
    cmp_ok $r, '<',  $l, "$r < $l";
    cmp_ok $r, '<=', $l, "$r <= $l";
    cmp_ok $l, 'gt', $r, "$l gt $r";
    cmp_ok $l, 'ge', $r, "$l ge $r";
    cmp_ok $r, 'lt', $l, "$r lt $l";
    cmp_ok $r, 'le', $l, "$r le $l";
}

# Compare to version objects.
my $semver = $CLASS->new('1.2.0');
for my $v (qw(
    1.002
    1.2.0
    v1.002
    v1.2.0
)) {
    my $version = version->new($v);
    ok $semver == $version, "$semver == $version";
}

# Compare to strings.
for my $v (qw(
    1.2.0
    v1.2.0
)) {
    my $semver = $CLASS->new($v);
    cmp_ok $semver, '==', $v, qq{$semver == "$v"};
    cmp_ok $v, '==', $semver, qq{"$v" == $semver};
    cmp_ok $semver, 'eq', $v, qq{$semver eq "$v"};
    cmp_ok $v, 'eq', $semver, qq{"$v" eq $semver};
}

# Test declare() and parse.
for my $spec (
    ['1.2.2',          '1.2.2'],
    ['01.2.2',         '1.2.2'],
    ['1.02.2',         '1.2.2'],
    ['1.2.02',         '1.2.2'],
    ['1.2.02b',        '1.2.2-b'],
    ['1.2.02beta-3  ', '1.2.2-beta-3'],
    ['1.02.02rc1',     '1.2.2-rc1'],
    ['1.0',            '1.0.0'],
    ['1.1',            '1.1.0',   '1.100.0'],
    [ 1.1,             '1.1.0',   '1.100.0'],
    ['1.1b1',          '1.1.0-b1', '1.100.0-b1'],
    ['1b',             '1.0.0-b'],
    ['9.0beta4',       '9.0.0-beta4'],
    ['  012.2.2',      '12.2.2'],
    ['99999998',       '99999998.0.0'],
    ['1.02_30',        '1.23.0'],
    [1.02_30,          '1.23.0'],
    [3.4,              '3.4.0', '3.400.0'],
    [3.04,             '3.4.0', '3.40.0' ],
    ['3.04',           '3.4.0', '3.40.0' ],
    [v3.4,             '3.4.0' ],
    [9,                '9.0.0' ],
    ['9',              '9.0.0' ],
    ['0',              '0.0.0' ],
    [0,                '0.0.0' ],
    ['0rc1',           '0.0.0-rc1' ],
) { SKIP: {
        skip 'Two-integer vstrings weak on Perl 5.8', 12
            if $no_2digitvst && Scalar::Util::isvstring($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    isa_ok my $l = SemVer->declare($spec->[0]), $CLASS, "Declared $spec->[0]";
    my $string = Scalar::Util::isvstring($spec->[0])
        ? join '.', map { ord } split // => $spec->[0] : $spec->[0];
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string += 0 if $string =~ s/_//g;
    my $vstring = $string =~ /^\d+[.][^.]+$/ ? "v$string" : $string;
    SKIP: {
        skip 'Stringification broken with version::vpp', 1, $is_vpp;
        is $l->stringify, $vstring, qq{... And it should stringify to "$vstring"};
    }
    is $l->normal, $spec->[1],  qq{... And it should normalize to "$spec->[1]"};

    # Compare the non-semantic version string to the semantic one.
    cmp_ok $spec->[0], '==', $r, qq{$r == "$spec->[0]"};

    if ($spec->[0] && $spec->[0] !~ /^[a-z]/ && $spec->[0] !~ /[.]{2}/) {
        my $exp = $spec->[2] || $spec->[1];
        isa_ok $l = SemVer->parse($spec->[0]), $CLASS, "Parsed $spec->[0]";
        $string = "v$string" if Scalar::Util::isvstring($spec->[0]);
        $string =~ s/_//;
        is $l->stringify, $string, "... And it should stringify to $string";
        is $l->normal,    $exp,    "... And it should normalize to $exp";

        # Try with the parsed version.
        $r = $CLASS->new($spec->[2]) if $spec->[2];
        cmp_ok $l, '==', $r, qq{$l == $r} unless $string =~ /_/;
    }

    # Try creating as a version object and cloning.
    if ($spec->[0] !~ /[a-z]/i) {
        isa_ok my $v = version->parse($spec->[0]), 'version', "base version $spec->[0]";
        isa_ok my $sv = SemVer->new($v), 'SemVer', "SemVer from base version $spec->[0]";
        is $sv->stringify, $string, qq{... And it should stringify to "$vstring"};
        SKIP: {
            skip 'version 0.9911 broke alpha->normal()', 1,
                if $spec->[0] =~ /_/ && version->VERSION == 0.9911;
            is $sv->normal, $l->normal,
                '... And it should normalize to "' . $l->normal . '"';
        }
    }
}}
