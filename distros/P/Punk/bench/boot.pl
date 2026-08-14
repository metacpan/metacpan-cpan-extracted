#!/usr/bin/env perl
use strict;
use warnings;

# What an app costs before it serves anything: the wall time to load the
# .psgi and return a PSGI coderef, and the resident set that leaves behind.
# Each app is measured in its own child from a clean interpreter, so the
# figures are per-framework rather than cumulative.
#
# Usage: perl bench/boot.pl [REPS] [apps...]

use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch",
        "$FindBin::Bin/../lib";
use Time::HiRes ();

my $REPS = $ARGV[0] || 5;
my @APPS = @ARGV[1 .. $#ARGV];

unless (@APPS) {
    opendir my $dh, "$FindBin::Bin/apps" or die $!;
    @APPS = sort map { s/\.psgi\z//r } grep { /\.psgi\z/ } readdir $dh;
}

sub rss_kb {
    my ($kb) = `ps -o rss= -p $$` =~ /(\d+)/;
    return $kb || 0;
}

# One child per measurement: boot the app, report (seconds, RSS delta).
sub boot_one {
    my ($file) = @_;
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        close $r;
        my $base  = rss_kb();
        my $start = Time::HiRes::time();
        my $app   = do $file;
        my $secs  = Time::HiRes::time() - $start;
        my $used  = rss_kb() - $base;
        open STDERR, '>', '/dev/null';
        print {$w} (ref $app eq 'CODE' ? "$secs $used\n" : "0 0\n");
        close $w;
        exit 0;
    }
    close $w;
    my $line = <$r>;
    waitpid $pid, 0;
    chomp $line;
    return split ' ', $line;
}

printf "%-16s %10s %12s\n", 'app', 'boot (ms)', 'RSS (KB)';
for my $name (@APPS) {
    my $file = "$FindBin::Bin/apps/$name.psgi";
    my (@secs, @rss);
    for (1 .. $REPS) {
        my ($s, $k) = boot_one($file);
        push @secs, $s;
        push @rss,  $k;
    }
    my ($secs) = sort { $a <=> $b } @secs;   # best of REPS
    my ($rss)  = sort { $a <=> $b } @rss;
    printf "%-16s %10.1f %12d\n", $name, 1000 * $secs, $rss;
}
