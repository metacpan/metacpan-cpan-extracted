#!perl -w
use strict;
use warnings;
use Test::DistManifest;

# When making the dist, MANIFEST.SKIP isn't copied, so check in the parent
# dir, which is the actual dist root, as well.

my $manifest = 'MANIFEST';
unless (-e $manifest) {
    $manifest = "../$manifest";
    warn "# using $manifest\n";
}

my $manifest_skip = 'MANIFEST.SKIP';
unless (-e $manifest_skip) {
    $manifest_skip = "../$manifest_skip";
    warn "# using $manifest_skip\n";
}

manifest_ok($manifest, $manifest_skip);
