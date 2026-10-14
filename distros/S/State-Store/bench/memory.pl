#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use State::Store;
use HAMT::Map;

# Memory, by the resident size of a fresh process before and after: 10,000
# undo steps on a 10,000-key map, against keeping a copy of the hash for each
# step. 10,000 copies would be some gigabytes, so 100 are measured and the
# figure for 10,000 is a hundred times that. Each case runs in a child of
# its own. This one does not use Benchmark: it measures space, not time.
#
# Usage: perl bench/memory.pl

sub rss_kb {
    my $kb = `ps -o rss= -p $$ 2>/dev/null`;
    return defined $kb && $kb =~ /(\d+)/ ? $1 : 0;
}

sub grown {
    my ($label, $build) = @_;
    pipe(my $r, my $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $r;
        my %h = map { ("key$_" => $_) } 1 .. 10_000;
        my $m = HAMT::Map->new(%h);
        my $before = rss_kb();
        my $keep = $build->(\%h, $m);
        print {$w} rss_kb() - $before;
        close $w;
        exit 0;
    }
    close $w;
    my $kb = do { local $/; <$r> };
    waitpid $pid, 0;
    printf "  %-44s %9.1f MB\n", $label, $kb / 1024;
    return $kb;
}

print "resident memory grown; perl $], $^O\n\n";
print "undo steps on a 10,000-key map, one key changed each step\n";
my $store = grown('10,000 steps in a store', sub {
    my (undef, $m) = @_;
    my $s = State::Store->new($m);
    $s->swap(sub { $_[0]->set("key" . (1 + $_ % 10_000) => -$_) }) for 1 .. 10_000;
    $s;
});
my $copies = grown('100 copies of the hash', sub {
    my ($h) = @_;
    my %live = %$h;
    my @stack;
    for (1 .. 100) { push @stack, { %live }; $live{"key$_"} = -$_ }
    \@stack;
});
printf "  10,000 steps in a store are 1/%.0f of 10,000 copies (a hundred times the 100 measured)\n",
    $copies * 100 / $store if $store;
