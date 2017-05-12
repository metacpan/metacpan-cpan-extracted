#!/usr/bin/env perl
use strict;
use Test::More tests => 5;
use lib 't';
use Data::Dump qw( dump );

use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::HiLiter');

my $file = 't/docs/pre-existing.txt';
my $q    = qq/pre-existing/;
my $buf  = Search::Tools->slurp($file);

my $snipper = Search::Tools::Snipper->new(
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
    treat_phrases_as_singles => 0,    # keep phrases together

    #debug                    => 1,

);

my $hiliter = Search::Tools::HiLiter->new( query => $q );

#dump $snipper;

ok( my $snip = $snipper->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );
ok( my $hilited = $hiliter->hilite($snip), "hilite" );

#diag($hilited);
