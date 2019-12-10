#!/usr/bin/env perl
use strict;
use utf8;
use NewsExtractor;
use File::Slurp qw< write_file >;

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
my (@urls_err_download, @urls_err_parse, @urls_good);
my ($count_all, $count_success, $count_err_download, $count_err_parse) = (0,0,0,0);
while(<>) {
    chomp;
    my $url = $_;

    $count_all++;
    my $err = try_extract($url);

    if ($err == 0) {
        $count_success++;
        push @urls_good, $url;
    } elsif ($err == 1) {
        $count_err_download++;
        push @urls_err_download, $url;
    } elsif ($err == 2) {
        $count_err_parse++;
        push @urls_err_parse, $url;
    }

    printf "%8d/%-8d - %8d,%8d: %s - %s\n", $count_success, $count_all, $count_err_download, $count_err_parse, ($err ? "(x)" : "(o)"), $url;
}

printf "%8d/%-8d\n", $count_success, $count_all;

write_file('urls-good.txt', join("\n", @urls_good));
write_file('urls-error-download.txt', join("\n", @urls_err_download));
write_file('urls-error-parse.txt', join("\n", @urls_err_parse));
