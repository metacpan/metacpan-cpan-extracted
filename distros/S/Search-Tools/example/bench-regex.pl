#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::Tokenizer;
use Benchmark qw(:all);
use File::Slurp;

my $ascii     = read_file('t/docs/test.txt');
my $tokenizer = Search::Tools::Tokenizer->new;
my $q         = qr/^(recense|checkerbreast|cannon)$/i;

cmpthese(
    1000,
    {   'token_overload' => sub {
            my $tokens = $tokenizer->tokenize( $ascii, $q );
            while ( my $tok = $tokens->next ) {
                "$tok";
            }
        },
        'token_str' => sub {
            my $tokens = $tokenizer->tokenize( $ascii, $q );
            while ( my $tok = $tokens->next ) {
                $tok->str;
            }
        },
    }
);

