#!/usr/bin/env perl

use strict;
use Test::More;
use File::Basename;

use_ok 'Parse::SNI';

my $path = dirname(__FILE__);

for my $sni_file (<$path/bad_sni/*.sni>) {
    open my $fh, '<', $sni_file or die "$sni_file: $!";
    my $data = do { local $/; <$fh> };
    ok !eval { parse_sni($data) }, "parse failed: $sni_file";
}

for my $sni_file (<$path/good_sni/*.sni>) {
    open my $fh, '<', $sni_file or die "$sni_file: $!";
    my $data = do { local $/; <$fh> };
    is scalar eval { parse_sni($data) }, basename($sni_file, '.sni'),  "parse success: $sni_file";
}

open my $fh, '<', "$path/good_sni/medium.com.sni" or die $!;
my $data = do { local $/; <$fh> };
my ($sni, $pos) = parse_sni($data);
is_deeply [ $sni, $pos ], [ 'medium.com', 151 ], 'got sni with position in list context';
is substr($data, $pos, length($sni)), 'medium.com', 'got same sni extracted from original data by position';

done_testing;
