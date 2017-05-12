#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib 't';
use Data::Dump qw( dump );
use_ok('Search::Tools::Tokenizer');

my $file = 't/docs/snip-phrases.txt';
my $buf  = Search::Tools->slurp($file);

# test sentence detection in Tokenizer first
my $tokenizer       = Search::Tools::Tokenizer->new();
my $tokens          = $tokenizer->tokenize( $buf, qr/john/ );
my $sentence_starts = $tokens->get_sentence_starts();
my $heat            = $tokens->get_heat();

#dump($sentence_starts);
is_deeply( $sentence_starts, [108], "sentence_starts" );

#undef $tokens;

#diag("Search::Tools::XS_DEBUG=$Search::Tools::XS_DEBUG");

my $tokenizer2       = Search::Tools::Tokenizer->new();
my $tokens2          = $tokenizer2->tokenize( $buf, qr/john/ );
my $sentence_starts2 = $tokens2->get_sentence_starts();
my $heat2            = $tokens2->get_heat();

#dump($sentence_starts2);
is_deeply( $sentence_starts2, [108], "sentence_starts" );
