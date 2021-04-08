#!/usr/bin/env perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Benchmark qw/timethis timethese/;
use MyTest;
use Protocol::HTTP::Request;

say $$;

die "usage: $0 <what> [--profile]" unless @ARGV;

my @cmds;
my $time = -1;
for (@ARGV) {
    $time = -10, next if m/--profile/;
    push @cmds, $_;
}

for (@cmds) {
    no strict 'refs';
    say "$_";
    
    if (my $sub = main->can($_)) {
        $sub->();
    } else {
        my $sub = MyTest->can("bench_$_") or die "unknown $_";
        timethis($time, $sub);
        #$sub->();
    }
}

say "DONE";
