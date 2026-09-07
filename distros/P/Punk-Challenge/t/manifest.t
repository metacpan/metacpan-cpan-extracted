#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
if ( eval "use Test::CheckManifest $min_tcm; 1" ) {
    ok_manifest();
    done_testing;
    exit 0;
}

# Test::CheckManifest is not installed. Rather than skip - a skip reads as a
# pass, and a header missing from MANIFEST is a distribution that compiles
# here and fails on every smoker - do the comparison directly.
diag("Test::CheckManifest $min_tcm not installed; comparing MANIFEST by hand");

my @skip = (
    qr{^blib/}, qr{^Punk-Challenge-}, qr{^Makefile$}, qr{^Makefile\.old$},
    qr{^MYMETA\.}, qr{^META\.}, qr{^pm_to_blib$}, qr{^ignore\.txt$},
    qr{\.(?:c|o|obj|bs|tar\.gz)$},
    # a dot file ANYWHERE, not only at the top
    qr{(?:^|/)\.},
);

sub skipped { my $p = shift; for my $r (@skip) { return 1 if $p =~ $r } 0 }

my %listed;
open my $fh, '<', 'MANIFEST' or plan skip_all => "no MANIFEST here: $!";
while (<$fh>) {
    chomp;
    s/\s.*\z//;              # the trailing comment column
    next unless length;
    next if /^#/;
    # the distdir MANIFEST gains META.json/META.yml, which the walk skips
    next if skipped($_);
    $listed{$_} = 1;
}
close $fh;

my @found;
my @todo = ('.');
while (my $dir = shift @todo) {
    opendir my $dh, $dir or next;
    for my $e (sort readdir $dh) {
        next if $e eq '.' || $e eq '..';
        my $p = $dir eq '.' ? $e : "$dir/$e";
        next if skipped($p);
        if (-d $p) { push @todo, $p; next }
        push @found, $p;
    }
    closedir $dh;
}

my @missing = grep { !$listed{$_} } @found;
my %on_disk = map { $_ => 1 } @found;
my @stale   = grep { !$on_disk{$_} } sort keys %listed;

unless (is_deeply(\@missing, [], 'every file on disk is in MANIFEST')) {
    diag("not in MANIFEST: $_") for @missing;
}
unless (is_deeply(\@stale, [], 'every file in MANIFEST is on disk')) {
    diag("listed but absent: $_") for @stale;
}
cmp_ok(scalar @found, '>', 10, 'and the walk actually found files');

done_testing;
