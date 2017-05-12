#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 8;
use Search::Tools;

use_ok('Search::Tools::Query');

my $text = 'one two three four lobotomy';
my $html = 'one <b>t</b>wo three <strong>four</strong> lobotomy';

ok( my $query = Search::Tools->parser->parse('two'), "new query" );
is( $query->matches_text($text), 1, "one text match" );
is( $query->matches_html($html), 1, "one html match" );

ok( my $qp = Search::Tools->parser(
        lang    => 'en_us',
        stemmer => sub {

            #warn "$_[1]";
            if ( $_[1] eq 'lobotomy' ) { return 'lobotomi'; }
            return $_[1];
        }
    ),
    "new stemming parser"
);

ok( my $stem_query = $qp->parse('lobotomy'), "new stemmed query" );
is( $stem_query->matches_text($text), 1, "one stemmed text match" );
is( $stem_query->matches_html($html), 1, "one stemmed html match" );
