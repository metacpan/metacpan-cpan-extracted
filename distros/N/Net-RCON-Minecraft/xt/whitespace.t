#!perl

use 5.008;
use Test::More;
no warnings 'uninitialized';

open my $manifest, '<', 'MANIFEST'
    or skip_all => "Can't open MANIFEST: $!";

my %files;

for my $file (sort map { (split /\s+/)[0] } <$manifest>) {
    my $fh;
    unless (open $fh, '<', $file) {
        $files{$file} = "Can't open: $!";
        next;
    }
    while (local $_ = <$fh>) {
        chomp;
        $files{$file} .= "Line $.: Trailing whitespace\n" if /\s+$/;
        $files{$file} .= "Line $.: Tab characters used\n" if /\t/;
    }
}

if (%files) {
    fail scalar(keys %files) . " files had whitespace problems:";
    for my $file (sort keys %files) {
        my @err = split /\n/, $files{$file};
        diag "$file: $_" for @err;
    }
} else {
    ok 1, 'All files have proper whitespace';
}

done_testing;
