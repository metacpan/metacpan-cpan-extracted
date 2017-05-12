use strict;
use Test::More tests => 13;

use_ok('Search::Tools');

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

my %q = (
    'the quick'             => 'quick',        # stopwords
    '"the quick brown fox"' => 'quick fox',    # phrase stopwords

);

ok( my $qparser = Search::Tools->parser(
        lang      => 'en_us',
        stopwords => 'the brown'
    ),

    "new parser"
);

test_parser($qparser);

ok( $qparser = Search::Tools->parser(
        lang      => 'en_us',
        stopwords => [qw(the brown)]
    ),

    "new parser"
);

test_parser($qparser);

sub test_parser {

    ok( my $query = $qparser->parse( join( ' ', keys %q ) ), "parse query" );

    for my $term ( @{ $query->terms } ) {
        my $r     = $query->regex_for($term);
        my $plain = $r->plain;
        my $html  = $r->html;

        like( $term, qr{^$plain$}, $term );
        like( $term, qr{^$html$},  $term );

        #diag($plain);

    }

}
