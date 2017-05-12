#!/usr/bin/env perl

use strict;
use Test::More tests => 18;
use Data::Dump qw( dump );

use_ok('Search::Tools');

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

my %q = (
    'the apples' => 'apple',    # stopwords

);

ok( my $qparser = Search::Tools->parser(
        lang      => 'en_us',
        stopwords => 'the brown',
        stemmer   => sub {
            my $w = $_[1];
            $w =~ s/s$//;
            return $w;

        }
    ),

    "new qparser"
);

ok( my $query = $qparser->parse( join( ' ', keys %q ) ), "parse query" );

#Data::Dump::dump $kw;

is( $query->num_terms, 1, "1 term" );

for my $term ( @{ $query->terms } ) {
    my $r     = $query->regex_for($term);
    my $plain = $r->plain;
    my $html  = $r->html;

    like( $term, qr{^$plain$}, $term );
    like( $term, qr{^$html$},  $term );

    #diag($plain);

}

# our stem -> regex is very naive. illustration:
ok( my $qp = Search::Tools->parser(
        lang    => 'en_us',
        stemmer => sub {
            if ( $_[1] eq 'dying' ) { return 'die'; }
            return $_[1];
        }
    ),
    "show naive stemming"
);

ok( my $naive = $qp->parse('"prison must" and dying'), "parse dying" );

#diag( dump $naive );
is_deeply( $naive->terms, [ 'prison* must*', 'die*' ], "stemmed terms" );

my $txt = qq/
I lived as a prisoner must and I was slowly, inevitably,
as all living things do, shuffling off the mortal coil,
eating dust, scanning these crowds for the pale rider,
in a word: dying.
/;

ok( my $snipper = Search::Tools->snipper(
        query        => $naive,
        occur        => 2,
        as_sentences => 1,

        #debug         => 1,
        ignore_length => 1,
    ),
    "new stemming snipper"
);
ok( my $snipped_naive = $snipper->snip($txt), "snip naive text" );
my $txt_nonewlines = $txt;
$txt_nonewlines =~ s/\n/ /g;
$txt_nonewlines =~ s/\s*$//;
is( $snipped_naive, $txt_nonewlines, "snipped stemmed match" );

ok( my $stemming_hiliter = Search::Tools->hiliter(
        query => $naive,

        #debug => 1,

        #tty   => 1,
    ),
    "stemming hiliter"
);
ok( my $hilited_naive = $stemming_hiliter->hilite($snipped_naive),
    "hilite snipped_naive" );
is( $hilited_naive,
    qq( I lived as a <span style='background:#ffff99'>prisoner</span> <span style='background:#ffff99'>must</span> and I was slowly, inevitably, as all living things do, shuffling off the mortal coil, eating dust, scanning these crowds for the pale rider, in a word: <span style='background:#99ffff'>dying</span>.),
    "hiliter stems"
);

#diag($hilited_naive);

ok( my $quirky_query = $qp->parse('"the quirky 7th district"'),
    "create phrase query" );
ok( $quirky_query->matches_html(
        qq(I live in the <b>quirky 7th district</b> of my town.)),
    "phrase matches_html"
);
ok( $quirky_query->matches_text(
        qq(I live in the quirky 7th district of my town.)),
    "phrase matches_html"
);

#diag( dump $quirky_query->terms );
