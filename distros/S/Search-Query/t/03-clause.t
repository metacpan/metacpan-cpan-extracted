#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;
use Data::Dump qw( dump );

use_ok('Search::Query');
use_ok('Search::Query::Clause');

ok( my $parser = Search::Query->parser(
        dialect       => 'SWISH',
        fields        => [qw( a color )],
        default_field => 'a',
    ),
    "new parser"
);

ok( my $clause = Search::Query::Clause->new(
        field => 'color',
        op    => '=',
        value => 'green',
    ),
    "create clause"
);
ok( my $query = $parser->parse("color=red"), "parse query" );
ok( $query->add_or_clause($clause), "add_or_clause" );
is( "$query", qq/(color=red) OR (color=green)/, "stringify" );
ok( $query->add_sub_clause( $parser->parse("color=(blue OR yellow)") ),
    "add sub_clause" );
is( "$query",
    qq/((color=red) OR (color=green)) AND ((color=blue OR color=yellow))/,
    "sub_clause stringify"
);

# roundtrip
ok( $parser->parse("$query"), "round-trip '$query'" );
diag( $parser->error ) if $parser->error;
$parser->clear_error;

ok( $query = $parser->parse("(foo or bar) or (green and red)"),
    "parse compound clauses" );
ok( $query->add_and_clause(
        Search::Query::Clause->new(
            field => 'color',
            op    => '=',
            value => 'brown',
        )
    ),
    "add and_clause"
);
ok( $query->add_not_clause(
        Search::Query::Clause->new(
            field => 'color',
            op    => ':',
            value => 'purple',
        )
    ),
    "add not_clause"
);
is( "$query",
    qq/(((a=foo OR a=bar) OR (a=green AND a=red)) AND (color=brown)) NOT (color=purple)/,
    "stringify compound query"
);

# roundtrip
ok( $parser->parse("$query"), "round-trip '$query'" );
diag( $parser->error ) if $parser->error;
$parser->clear_error;

