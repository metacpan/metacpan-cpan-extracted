#!/usr/bin/perl
use Plucene::SearchEngine::Index;
use Test::More tests => 4;

# Need to hack this so that the HTML handler doesn't see us
Plucene::SearchEngine::Index::RSS->register_handler("text/html");

my @articles = Plucene::SearchEngine::Index::File->examine("t/planetperl.rss");
is (@articles, 63, "Found all the articles");
my $interesting = $articles[59];
is($interesting->{creator}{data}[0], "David Wheeler", "Found creator");
like($interesting->{text}{data}[0], qr/most of last week/, "Got content");
like($interesting->{id}{data}[0], qr/atheory.*in.*planet/, "Got URLs");
