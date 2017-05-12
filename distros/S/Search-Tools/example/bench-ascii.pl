#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Benchmark qw(:all);
use File::Slurp;

my $ascii      = read_file('t/docs/test.txt');
my $ascii_utf8 = to_utf8($ascii);
my $ascii_xs   = $ascii;                            # no utf8 flag!
my $tokenizer  = Search::Tools::Tokenizer->new();

cmpthese(
    1000,
    {   'ascii-pp' => sub {
            my $tokens = $tokenizer->tokenize_pp($ascii);
        },
        'ascii_utf8-pp' => sub {
            my $tokens = $tokenizer->tokenize_pp($ascii_utf8);
        },
        'ascii-xs' => sub {
            my $tokens = $tokenizer->tokenize($ascii_xs);
        },
        'ascii_utf8-xs' => sub {
            my $tokens = $tokenizer->tokenize($ascii_utf8);
        },
    }
);

sub heat_seeker {

    # trivial case
}

