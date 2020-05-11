#!/usr/bin/perl -w

# Test the SemVer corpus from https://regex101.com/r/Ly7O1x/3/.

use strict;
use warnings;
use Test::More tests => 222;
#use Test::More 'no_plan';

use FindBin qw($Bin);
use lib "$Bin/../lib";
use SemVer;

# Valid Semantic Versions
for my $v (qw(
    0.0.4
    1.2.3
    10.20.30
    1.1.2-prerelease+meta
    1.1.2+meta
    1.1.2+meta-valid
    1.0.0-alpha
    1.0.0-beta
    1.0.0-alpha.beta
    1.0.0-alpha.beta.1
    1.0.0-alpha.1
    1.0.0-alpha0.valid
    1.0.0-alpha.0valid
    1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
    1.0.0-rc.1+build.1
    2.0.0-rc.1+build.123
    1.2.3-beta
    10.2.3-DEV-SNAPSHOT
    1.2.3-SNAPSHOT-123
    1.0.0
    2.0.0
    1.1.7
    2.0.0+build.1848
    2.0.1-alpha.1227
    1.0.0-alpha+beta
    1.2.3----RC-SNAPSHOT.12.9.1--.12+788
    1.2.3----R-S.12.9.1--.12+meta
    1.2.3----RC-SNAPSHOT.12.9.1--.12
    1.0.0+0.build.1-rc.10000aaa-kk-0.1
    1.0.0-0A.is.legal
)) {
    local $@;
    ok my $sv = eval { SemVer->new($v) }, qq{New "$v" should be valid} or diag $@;
    is $sv->stringify, $v, qq{Should stringify to "$v"};

    ok $sv = eval { SemVer->declare($v) }, qq{Declare "$v" should work} or diag $@;
    is $sv->stringify, $v, qq{Should stringify to "$v"};

    ok $sv = eval { SemVer->parse($v) }, qq{Parse "$v" should work} or diag $@;
    is $sv->stringify, $v, qq{Should stringify to "$v"};
}

SKIP: {
    local $TODO = 'Large versions overflow version.pm integer bounds';
    local $SIG{__WARN__} = sub { }; # Ignore version overflow warning
    my $v = '99999999999999999999999.999999999999999999.99999999999999999';
    ok my $sv = eval { SemVer->new($v) }, qq{"$v" should be valid};
    is $sv->stringify, $v, qq{Should stringify to "$v"};
}

# Invalid Semantic Versions
for my $bv (qw(
    1
    1.2
    1.2.3-0123
    1.2.3-0123.0123
    1.1.2+.123
    +invalid
    -invalid
    -invalid+invalid
    -invalid.01
    alpha
    alpha.beta
    alpha.beta.1
    alpha.1
    alpha+beta
    alpha_beta
    alpha.
    alpha..
    beta
    1.0.0-alpha_beta
    -alpha.
    1.0.0-alpha..
    1.0.0-alpha..1
    1.0.0-alpha...1
    1.0.0-alpha....1
    1.0.0-alpha.....1
    1.0.0-alpha......1
    1.0.0-alpha.......1
    01.1.1
    1.01.1
    1.1.01
    1.2
    1.2.3.DEV
    1.2-SNAPSHOT
    1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788
    1.2-RC-SNAPSHOT
    -1.0.3-gamma+b7718
    +justmeta
    9.8.7+meta+meta
    9.8.7-whatever+meta+meta
    99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12
)) {
    local $@;
    eval { SemVer->new($bv) };
    ok $@, qq{"$bv" should be an invalid semver};
}
