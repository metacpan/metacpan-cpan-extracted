#!/usr/bin/perl
use strict;
use warnings;

# Transform test files to remove subtest blocks for Perl 5.10 compatibility
# subtest 'name' => sub { ... }; becomes # name\n{ ... }

my @files = @ARGV;
for my $file (@files) {
    open my $fh, '<', $file or die "Cannot read $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my $orig = $content;

    # Replace subtest 'name' => sub { with # name + bare block
    $content =~ s/^subtest\s+'([^']+)'\s*=>\s*sub\s*\{\s*$/# $1\n{/gm;

    # Replace top-level }; (column 0, no leading whitespace) with }
    # These are the subtest closings
    $content =~ s/^};\s*$/}/gm;

    if ($content ne $orig) {
        open my $out, '>', $file or die "Cannot write $file: $!";
        print $out $content;
        close $out;
        print "Fixed: $file\n";
    } else {
        print "No changes: $file\n";
    }
}
