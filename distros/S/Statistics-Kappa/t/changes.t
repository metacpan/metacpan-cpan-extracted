#!/usr/bin/perl
use warnings;
use strict;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

use FindBin;
use Test::More;

use Statistics::Kappa::Cohen;
use Statistics::Kappa::Fleiss;
use Statistics::Kappa::Weighted;

plan(tests => 7);

eval 'use Statistics::Kappa';
my $version = $Statistics::Kappa::VERSION;
my $vc = $Statistics::Kappa::Cohen::VERSION;
my $vf = $Statistics::Kappa::Fleiss::VERSION;
my $vw = $Statistics::Kappa::Weighted::VERSION;

is $vc, $version, 'same version in c';
is $vf, $version, 'same version in f';
is $vw, $version, 'same version in w';

my $changes_file = "$FindBin::Bin/../Changes";
ok open my $CH, '<', $changes_file;

my $date_re = qr/\d{4}-\d{2}-\d{2}/;
my $version_re = qr/\d\.\d{2,3}(?:_\d{2,3})?/;
my ($found, $format) = (0, 1);
my $most_recent;
while (<$CH>) {
    $most_recent = $1 if ! $most_recent && /^($version_re)\s+$date_re$/;
    $found++ if /\Q$version\E {3,4}$date_re$/;
    diag($_), undef $format unless /^(?:
                                      Revision\ history\ for\ Statistics-Kappa
                                      | $version_re \ {3,4} $date_re
                                      | \ {8} - \ .*
                                      | \ {10} .*
                                      | \ {8} [[:upper:]].+
                                      |
                                  )$ /x
}

is $found, 1, "$version found in changes";
ok $format, 'format';
is $most_recent, $version, "in sync ($most_recent == $version)";
