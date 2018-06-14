#!perl

use strict;
use warnings;

use Test2::V0;

use Python::Version;

my %version_strings = (
    '1.2.3rc2.dev1+ubuntu.1' => [
        qw(
          1.2.3.rc2-dev1+ubuntu-1
          1.2.3.c2-dev1+ubuntu-1
          1.2.3.pre2-dev1+ubuntu-1
          1.2.3-preview2_dev1+ubuntu-1
          )
    ],
    '2.0.1.5a1.dev2' => [
        qw(
          2.0.1.5.alpha1-dev2
          2.0.1.5-alpha1_dev2
          2.0.1.5alpha1_dev2
          2.0.1.5a1_dev2
          )
    ],
    '1!5.21.post0' => [
        qw(
          1!5.21-0
          1!5.21post
          1!5.21rev
          1!5.21.r
          )
    ],
);

for my $normalized ( sort keys %version_strings ) {
    {
        my $v = Python::Version->parse($normalized);
        is( $v->normal, $normalized, "$normalized -> $normalized" );

        if ( $normalized =~ /pre/ ) {
            ok( $v->is_prerelease,   "is_prerelease" );
            ok( !$v->is_postrelease, "!is_postrelease" );
        }
        if ( $normalized =~ /post/ ) {
            ok( !$v->is_prerelease, "!is_prerelease" );
            ok( $v->is_postrelease, "is_postrelease" );
        }
        if ( $normalized =~ /dev/ ) {
            ok( $v->is_devrelease, "is_devrelease" );
        }
    }

    for my $vstr ( @{ $version_strings{$normalized} } ) {
        my $v = Python::Version->parse($vstr);
        is( $v->normal,   $normalized, "$vstr -> $normalized" );
        is( $v->original, $vstr,       'original()' );
    }
}

my @vcmp_cases = (
    '1.2.3 == 1.2.3',
    '1.2 < 1.2.3',
    '1.2.1 < 1.2.3',
    '1.21 > 1.3',
    '1.2.3 > 1.2.3pre1',
    '1.2.3.dev2 < 1.2.3pre1',
    '2018.1 > 1.3',
    '2018.1 < 1!1.3',
    '1.2pre1 < 1.2pre2',
    '1.2pre1 < 1.2pre2',
    '1.2pre1 > 1.2pre1.dev0',
    '1.2pre1 < 1.2.post0',
    '1.2.post0 < 1.2.post1',
    '1.2.post0 > 1.2.post0.dev2',
    '1.2+ubuntu.1 < 1.2+ubuntu.2',
    '1.2.post0+ubuntu.1 > 1.2+ubuntu.2',
    '1.2.post0+ubuntu.1 == 1.2.post0+ubuntu-1',
);

for my $case (@vcmp_cases) {
    my ( $left, $op, $right ) = split( /\ +/, $case );

    my $rslt = eval "Python::Version->parse('$left') $op '$right'";
    if ($@) {
        diag($@);
    }
    ok( $rslt, $case );
}

done_testing;
