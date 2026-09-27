#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

use FindBin;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

plan(tests => 7);

{   my @versions;
    sub version {
        push @versions, shift;
        is $versions[-1], $versions[0], 'same' if @versions > 1;
    }
}

for my $module (qw( Statistics/Kappa
                    Statistics/Kappa/Cohen
                    Statistics/Kappa/Fleiss
                    Statistics/Kappa/Weighted
)) {
    open my $src, '<', "$FindBin::Bin/../lib/$module.pm" or die $module;
    my $in_pod_version;
    while (<$src>) {
        version($1) if /^\s*our \$VERSION = '([0-9.]+)';$/;
        $in_pod_version = 1 if /^=head1 VERSION$/;
        version($1), undef $in_pod_version
            if $in_pod_version && /^Version ([0-9.]+)$/;
    }
}
