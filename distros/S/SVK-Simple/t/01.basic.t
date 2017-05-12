#!/usr/bin/perl
use strict;
use warnings;
use SVK::Simple;

my %param;
my $no_skip;
BEGIN {
    if($ARGV[0]) {
        $param{tests} = 2;
        $no_skip=1;
    } else {
        $param{skip_all} = "Need SVKROOT to test";
    }
}

use Test::More %param;

if($no_skip) {
    use Test::More;
    my $output;
    {
        my $svk = SVK::Simple->new();
        is(ref($svk),'SVK', "Return correct object");
    }
    {
        my $svk2 = SVK::Simple->new(output => \$output);
        is(ref($svk2),'SVK', "Return correct object");
    }
}

