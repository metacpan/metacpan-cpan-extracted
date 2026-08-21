#!/usr/bin/env perl

use v5.38;
use Test::More;
use File::Find;
use Path::Tiny;

plan skip_all => 'these tests are for authors only!'
    unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING});

my $lib_dir = path(__FILE__)->parent->parent->child('lib');

unless (-d $lib_dir) {
    plan skip_all => "Directory '$lib_dir' not found";
}

my @pm_files;
find(
    sub {
        push @pm_files, path($File::Find::name) if /\.pm$/;
    },
    $lib_dir
);

unless (@pm_files) {
    plan skip_all => "No .pm files found under lib/";
}

my $strict_version = qr/^v\d+\.\d+\.\d+(?:_\d+)?$/;

my %found_code_versions;

for my $file (@pm_files) {
    my $content  = $file->slurp_utf8;
    my $rel_path = $file->relative($lib_dir);

    my ($code_version) = $content =~ /our\s+\$VERSION\s*=\s*qv\(\s*['"]([^'"]+)['"]\s*\);/;
    my ($pod_version)  = $content =~ /=head1\s+VERSION\s*\n\n?(?:Version\s+)?([^\n\r]+)/i;
    $pod_version =~ s/\s+$// if defined $pod_version;

    ok(defined $code_version, "lib/$rel_path has \$VERSION in code");
    ok(defined $pod_version, "lib/$rel_path has =head1 VERSION in POD");
    is($code_version, $pod_version, "lib/$rel_path code version ($code_version) matches POD ($pod_version)");

    if (defined $code_version) {
        like(
            $code_version,
            $strict_version,
            "lib/$rel_path version '$code_version' follows strict semantic version format (vX.Y.Z)"
        );
        $found_code_versions{$code_version}++;
    } else {
        fail("lib/$rel_path version format check skipped (no version found)");
    }
}

my @unique_versions = keys %found_code_versions;
is(scalar @unique_versions, 1, "All .pm files share the exact same version number")
    or diag("Found mismatched versions across files: " . join(", ", @unique_versions));

done_testing;
