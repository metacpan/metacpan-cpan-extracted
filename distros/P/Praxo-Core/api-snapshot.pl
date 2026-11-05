#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Spec;

my $ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..', '..'));
my $SELF = File::Spec->rel2abs($FindBin::Bin);

sub read_text {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

my $version = read_text(File::Spec->catfile($SELF, 'VERSION'));
$version =~ s/^\s+|\s+$//g;
my $spec = read_text(File::Spec->catfile($ROOT, 'spec', 'SPEC_VERSION'));
$spec =~ s/^\s+|\s+$//g;

my @entries;
for my $path (sort glob(File::Spec->catfile($SELF, 'lib', 'Praxo', '*.pm'))) {
    my $text = read_text($path);
    my $package = 'main';
    for my $line (split /\n/, $text) {
        $package = $1 if $line =~ /^package\s+([A-Za-z0-9_:]+)/;
        if ($line =~ /^sub\s+([A-Za-z_][A-Za-z0-9_]*)/) {
            next if $1 =~ /^_/;
            push @entries, "$package\::$1";
        }
    }
}
@entries = sort @entries;
my %seen;
@entries = grep { !$seen{$_}++ } @entries;

my $content = join "\n",
    "# PRAXO-CORE Perl API $version",
    "# SPEC_VERSION $spec",
    "",
    @entries,
    "";

my $check = grep { $_ eq '--check' } @ARGV;
my $target = File::Spec->catfile($SELF, 'api', "$version.txt");
if ($check) {
    if (!-f $target) {
        print STDERR "missing snapshot: $target\n";
        exit 1;
    }
    if (read_text($target) ne $content) {
        print STDERR "snapshot is stale: $target\n";
        exit 1;
    }
    print "snapshot is current: $target\n";
} else {
    my $dir = File::Spec->catdir($SELF, 'api');
    mkdir $dir unless -d $dir;
    open my $fh, '>:raw', $target or die "write $target: $!\n";
    print {$fh} $content;
    close $fh;
    print "wrote $target\n";
}
