#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::Snipper;
use Benchmark qw(:all);
use File::Slurp;

my $ascii = read_file('t/docs/test.txt');
my $query = Search::Tools->parser->parse('recense "checkerbreast cannon"');
my $re_snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
    type      => 're',
);

my $loop_snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
    type      => 'loop',
);

my $offset_snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
    type      => 'offset',
);

my $token_snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
    type      => 'token',
);

cmpthese(
    1000,
    {   're' => sub {
            my $snip = $re_snipper->snip($ascii);
        },
        'loop' => sub {
            my $snip = $loop_snipper->snip($ascii);
        },
        'offset' => sub {
            my $snip = $offset_snipper->snip($ascii);
        },
        'token' => sub {
            my $snip = $token_snipper->snip($ascii);
        },
    }
);
