#!/usr/bin/env perl
use v5.18;
use strict;
use utf8;
use NewsExtractor;
use Encode qw< encode_utf8 >;
use File::Slurp qw< write_file >;

sub try_extract {
    my $url = $_[0];
    my $x = NewsExtractor->new( url => $url );
    my ($err, $y) = $x->download;
    return 1 if $err;
    ($err, my $article) = $y->parse;
    return 2 if $err;
    return (0, $article);
}

sub checkmark {
    my ($v) = @_;
    if ($v && $v ne '') {
        return "\x{02713}"; # CHECK MARK
    } else {
        return "\x{0274C}"; # CROSS MARK
    }
}

## main
my (@urls_err_download, @urls_err_parse, @urls_good);
my ($count_all, $count_success, $count_err_download, $count_err_parse) = (0,0,0,0);

say encode_utf8(join("\t", "Headline", "Dateline", "Journalist", "Body", "URL"));

while(<>) {
    chomp;
    my $url = $_;

    $count_all++;
    my ($err, $article) = try_extract($url);

    if ($err == 0) {
        $count_success++;
        push @urls_good, $url;
        say encode_utf8(
            join("\t",
                 checkmark($article->headline),
                 checkmark($article->dateline),
                 checkmark($article->journalist),
                 checkmark($article->article_body),
                 $url,
             )
         );
    } elsif ($err == 1) {
        $count_err_download++;
        push @urls_err_download, $url;
    } elsif ($err == 2) {
        $count_err_parse++;
        push @urls_err_parse, $url;
    }
}

printf "%8d/%-8d\n", $count_success, $count_all;

write_file('urls-good.txt', join("\n", @urls_good));
write_file('urls-error-download.txt', join("\n", @urls_err_download));
write_file('urls-error-parse.txt', join("\n", @urls_err_parse));
