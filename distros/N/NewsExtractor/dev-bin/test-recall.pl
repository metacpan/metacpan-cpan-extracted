#!/usr/bin/env perl
use strict;
use utf8;
use NewsExtractor;

sub try_extract {
    my $url = $_[0];
    my $x = NewsExtractor->new( url => $url );
    my ($err, $y) = $x->download;
    return 1 if $err;
    ($err, my $article) = $y->parse;
    return 2 if $err;
    return 0;
}

## main
my ($count_all, $count_success, $count_err_download, $count_err_parse) = (0,0,0,0);
while(<>) {
    chomp;
    my $url = $_;

    my $err = try_extract($url);
    if ($err == 0) {
        $count_success++;
    }
    $count_all++;

    $count_err_download++ if $err == 1;
    $count_err_parse++ if $err == 2;

    printf "%8d/%-8d - %8d,%8d: %s - %s\n", $count_success, $count_all, $count_err_download, $count_err_parse, ($err ? "(x)" : "(o)"), $url;
}

printf "%8d/%-8d\n", $count_success, $count_all;
