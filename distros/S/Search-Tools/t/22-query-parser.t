use Test::More tests => 25;
use strict;
use warnings;
use Data::Dump qw( dump );

use_ok('Search::Tools::QueryParser');

ok( my $qparser = Search::Tools::QueryParser->new(), "new qparser" );
ok( my $query = $qparser->parse('quick brown "foxy fox"'), "parse() query" );
ok( my $terms = $query->terms, "get terms" );
is( scalar @$terms, 3, "3 terms" );
ok( my $regex = $query->regex_for( $terms->[0] ), "regex_for" );
ok( $regex->isa('Search::Tools::RegEx'), "regex isa RegEx" );
like( $terms->[0], $regex->plain, "regex matches plain" );
like( $terms->[0], $regex->html,  "regex matches html" );
isnt( $query->str, $query->str_clean, "query->str isnt query->str_clean" );
ok( my $tree = $query->tree, "get tree" );
ok( $query, "test bool overload" );
is( $query, $query->str, "test string overload" );

# wildcards
my $wild_text = qq{a fancy word for detox? demythylation is not.};
ok( my $wild_end   = $qparser->parse('methyl*'),  "wildcard ending" );
ok( my $wild_start = $qparser->parse('*methyl'),  "wildcard start" );
ok( my $wild_both  = $qparser->parse('*methyl*'), "wildcard both" );

#diag( dump $wild_end );
#diag( dump $wild_start );
#diag( dump $wild_both );

for my $q ( $wild_end, $wild_start, $wild_both ) {
    my $term = $q->terms->[0];
    like( $term, $q->regex_for($term)->plain, "plain regex match $q" );
    like( $term, $q->regex_for($term)->html,  "html regex match $q" );
}

# range
ok( my $swish_parser = Search::Tools::QueryParser->new(), "new QueryParser" );
ok( my $range_query = $swish_parser->parse('date!=( 1..3 )'),
    "parse range query" );
is( $range_query, "date!=( 1..3 )", "$range_query stringified" );
