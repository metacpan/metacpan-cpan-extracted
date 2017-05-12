#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use File::Spec::Functions;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(rel2abs);

my $roast_base = rel2abs(glob("roast/"));
while (<>) {
    if (m!roast/(\S+) \.*\.\. ok!) {
        my $name = $1;
        next if $name eq 'S02-lexical-conventions/bom.t';

        my $srcpath = catfile($roast_base, $name);
        my $src = slurp($srcpath);
        my $dstpath =  "t/spec/roast/$name";
        mkpath dirname($dstpath);
        open my $fh, '>', $dstpath;
        print $fh "#! ./blib/script/seis\n";
        print $fh $src;
    }
}

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(do { local $/; <$fh> })
}
