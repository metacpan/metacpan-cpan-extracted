#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Time::HiRes qw(time);
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use Perl::Minify qw(minify);

# Benchmark suite for Perl::Minify

my @test_files = (
    { name => 'small', file => 'color.pl', iterations => 100 },
    { name => 'medium', file => 'lib/Perl/Minify.pm', iterations => 50 },
);

print "=" x 70, "\n";
print "Perl::Minify Benchmark Suite\n";
print "=" x 70, "\n\n";

for my $test (@test_files) {
    my $file = "$RealBin/$test->{file}";
    next unless -f $file;
    
    open my $fh, '<', $file or die "Cannot open $file: $!";
    local $/;
    my $code = <$fh>;
    close $fh;
    
    my $size = length($code);
    my $lines = scalar(split /\n/, $code);
    
    print "Test: $test->{name} ($test->{file})\n";
    print "  Size: $size bytes, $lines lines\n";
    
    # Benchmark default minification
    {
        my $start = time;
        for (1..$test->{iterations}) {
            minify($code);
        }
        my $elapsed = time - $start;
        my $per_iter = ($elapsed / $test->{iterations}) * 1000;
        my $throughput = ($size * $test->{iterations}) / $elapsed / 1024;
        
        printf "  Default minify: %.2f ms/iter, %.1f KB/s\n", $per_iter, $throughput;
    }
    
    # Benchmark with shorten_vars
    {
        my $start = time;
        for (1..$test->{iterations}) {
            minify($code, { shorten_vars => 1 });
        }
        my $elapsed = time - $start;
        my $per_iter = ($elapsed / $test->{iterations}) * 1000;
        my $throughput = ($size * $test->{iterations}) / $elapsed / 1024;
        
        printf "  With shorten_vars: %.2f ms/iter, %.1f KB/s\n", $per_iter, $throughput;
    }
    
    # Show compression ratio
    {
        my $minified = minify($code);
        my $ratio = 100 * (1 - length($minified) / $size);
        printf "  Compression: %.1f%% (%.0f -> %.0f bytes)\n", 
               $ratio, $size, length($minified);
    }
    
    print "\n";
}

print "=" x 70, "\n";
print "Benchmark complete\n";
