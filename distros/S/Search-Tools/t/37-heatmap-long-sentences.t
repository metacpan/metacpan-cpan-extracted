#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use Search::Tools::Snipper;
use Search::Tools::XML;
use Data::Dump qw( dump );


my $file = 't/docs/having-trouble-paying.html';
ok( my $html = Search::Tools->slurp($file), "read buf" );

#$html = Search::Tools::XML->strip_html($html);
#$html = Search::Tools::XML->strip_html($html);

my $q       = qq/"having trouble paying"/;
my $snipper = Search::Tools::Snipper->new(
    query                    => $q,
    treat_phrases_as_singles => 0,      # keep phrases together
    occur                    => 2,      # number of snips
    context                  => 200,    # number of words in each snip
    as_sentences             => 1,
    ignore_length => 1,    # ignore max_chars, return entire snippet.
    show          => 0,    # only show if match, no dumb substr
);

ok( my $snipped = $snipper->snip($html), "snip long sentence" );

#diag($html);
#diag($snipped);

