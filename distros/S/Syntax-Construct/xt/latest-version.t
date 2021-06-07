#! /usr/bin/perl
use warnings;
use strict;

use Test::More;

use FindBin;

sub sort_by_version {
    sort {
        my @A = split /\./, $a;
        my @B = split /\./, $b;
        $A[0] <=> $B[0] || $A[1] <=> $B[1] || $A[2] <=> $B[2]
    } @_
}

for my $dependency (qw( File::Fetch YAML )) {
    plan(skip_all => "$dependency needed to run latest version check")
         unless eval "require $dependency";
}

my $ci = eval { YAML::LoadFile("$FindBin::Bin/../.github/workflows/tester.yaml") }
    or plan(skip_all => "Can't find github actions config");

my $ff = 'File::Fetch'->new(uri => 'http://perl.org/index.html');
$ff->fetch(to => \ my $perl_org)
    or plan(skip_all => "Can't fetch perl.org");

my $version_re = qr/5\.[0-9]+\.[0-9]+/;
my $ci_version = (sort_by_version(
    map /($version_re)/,
    grep /$version_re/,
    @{ $ci->{jobs}{'matrix-tests'}{strategy}{matrix}{'perl-version'} }))[-1];

plan(tests => 2);
ok($perl_org =~ /version-highlight.*\Q$ci_version\E\b/, $ci_version);

my $doc_version = $ci_version;
$doc_version =~ s/\.[0-9]+$//;
$doc_version =~ s/\./.0/;

my $current_version = 0;
my $delta_links = 1;
open my $src, '<', "$FindBin::Bin/../lib/Syntax/Construct.pm" or die $!;
while (<$src>) {
    if (/^=head2 (5\.[0-9]+)/) {
        $current_version = $1;
    }
    if (my ($link) = /(L<.*perldelta.*>)/) {
        if ($current_version ne $doc_version
            || $ci_version !~ /\.0$/
        ) {
            diag "$link";
            $delta_links = 0;
        }
    }
}
ok($delta_links, 'Delta links');
