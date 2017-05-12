#!/usr/bin/env perl
use strict;
use Test::More tests => 22;
use lib 't';
use Data::Dump qw( dump );
use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::HiLiter');

my $file = 't/docs/snip-phrases.txt';
my $q    = qq/"united states"/;
my $buf  = Search::Tools->slurp($file);

my $snipper = Search::Tools::Snipper->new(
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
                             #debug         => 1,
    treat_phrases_as_singles => 0,    # keep phrases together
);

#dump $snipper;
ok( my $snip = $snipper->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

# proximity syntax
$q       = qq/"live united"~5/;
$snipper = Search::Tools::Snipper->new(
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
                             #debug         => 1,
    treat_phrases_as_singles =>
        0,    # keep phrases together, but snipper should detect proximity
);

#dump $snipper;

ok( $snip = $snipper->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

#diag($snip);

# snip a phrase with a dot
#diag("snip phrase with a dot");
$q = qq/"st. john's"/;
my $snipper2 = Search::Tools::Snipper->new(

    #debug         => 1,
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
    treat_phrases_as_singles =>
        0,    # keep phrases together, but snipper should detect proximity
);

#dump $snipper;

ok( $snip = $snipper2->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

#diag($snip);

######################################
# phrases and stemming, oh my!

ok( my $stemming_snipper = Search::Tools::Snipper->new(
        stemmer => sub {
            if ( $_[1] eq 'thing' ) { return 'thin'; }
            return $_[1];
        },
        query                    => qq/"st. john's wort" thing good/,
        occur                    => 1,
        as_sentences             => 1,
        treat_phrases_as_singles => 0,
        show                     => 1,
        ignore_length            => 1,
        context                  => 50,

        #debug                    => 1,
    ),
    "stemming snipper"
);
ok( my $stemmed_snip = $stemming_snipper->snip($buf), "stemmed snip buf" );

#diag($stemmed_snip);
like(
    $stemmed_snip,
    qr/st. john's wort is a good thing/,
    "stemmed snip match, yes sentences"
);

ok( $stemming_snipper = Search::Tools::Snipper->new(
        stemmer => sub {
            if ( $_[1] eq 'thing' ) { return 'thin'; }
            return $_[1];
        },
        query                    => qq/"st. john's wort" thing good/,
        occur                    => 1,
        as_sentences             => 0,
        treat_phrases_as_singles => 0,
        show                     => 1,
        ignore_length            => 1,
        context                  => 50,

        #debug                    => 1,
    ),
    "stemming snipper"
);
ok( $stemmed_snip = $stemming_snipper->snip($buf), "stemmed snip buf" );

#diag($stemmed_snip);
like(
    $stemmed_snip,
    qr/st. john's wort is a good thing/,
    "stemmed snip match, no sentences"
);

#
# duplicate terms in phrases
#
ok( $stemming_snipper = Search::Tools::Snipper->new(
        stemmer => sub {
            if ( $_[1] eq 'language' ) { return 'lang'; }
            return $_[1];
        },
        query        => qq/"english language" or "second language"/,
        occur        => 1,
        as_sentences => 0,
        treat_phrases_as_singles => 0,
        show                     => 1,
        ignore_length            => 1,
        context                  => 50,

        #debug => 1,
    ),
    "stemming snipper"
);
ok( $stemmed_snip = $stemming_snipper->snip($buf), "stemmed snip buf" );
is( $stemming_snipper->query->num_unique_terms, 3, "3 unique terms" );

#diag($stemmed_snip);
like(
    $stemmed_snip,
    qr/english language/,
    "stemmed snip match on duplicate terms"
);

ok( $stemming_snipper = Search::Tools::Snipper->new(
        stemmer => sub {
            if ( $_[1] eq 'language' ) { return 'lang'; }
            return $_[1];
        },
        query        => qq/"english language" or "second language"/,
        occur        => 1,
        as_sentences => 1,
        treat_phrases_as_singles => 0,
        show                     => 1,
        ignore_length            => 1,
        context                  => 50,

        #debug => 1,
    ),
    "stemming snipper"
);
ok( $stemmed_snip = $stemming_snipper->snip($buf), "stemmed snip buf" );
is( $stemming_snipper->query->num_unique_terms, 3, "3 unique terms" );

#diag($stemmed_snip);
like(
    $stemmed_snip,
    qr/english language/,
    "stemmed snip match on duplicate terms as sentences"
);
