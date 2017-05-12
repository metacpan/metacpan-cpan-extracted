#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::Snipper;
use Search::Tools::XML;
use Benchmark qw(:all);
use File::Slurp;

my $html  = read_file('t/docs/big-C-Child-abuse.html');
my $buf   = Search::Tools::XML->strip_markup($html);
my $query = Search::Tools->parser->parse('child abuse');

my $snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
);

my $sentence_snipper = Search::Tools::Snipper->new(
    query        => $query,
    occur        => 1,
    context      => 25,
    max_chars    => 190,
    as_sentences => 1,
);

cmpthese(
    100,
    {   'no-sentences' => sub {
            my $snip = $snipper->snip($buf);
        },

        'sentences' => sub {
            my $snip = $sentence_snipper->snip($buf);
        },
    }
);
