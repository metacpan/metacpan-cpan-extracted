#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 32;
use Data::Dump qw( dump );

use_ok('Search::QueryParser::SQL');

ok( my $parser = Search::QueryParser::SQL->new(
        columns        => [qw( foo color name )],
        default_column => 'name'
    ),
    "new parser"
);

my $rdbo;

ok( my $query1 = $parser->parse('foo=bar'), "query1" );
$rdbo = $query1->rdbo;

#warn dump $rdbo;
is_deeply( $rdbo, [ 'foo', 'bar' ], "query1 values" );

ok( my $query2 = $parser->parse('foo:bar'), "query2" );
$rdbo = $query2->rdbo;

#warn dump $rdbo;
is_deeply( $rdbo, [ 'foo', 'bar' ], "query2 values" );

ok( my $query3 = $parser->parse( 'foo bar', 1 ), "query3" );
$rdbo = $query3->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   'AND' => [
            name => 'foo',
            name => 'bar',
        ]
    ],
    "query3 values"
);

ok( my $query4 = $parser->parse( '-color:red (name:john OR foo:bar)', 1 ),
    "query4" );
$rdbo = $query4->rdbo;

#warn dump $rdbo;

#"((name='john') OR (foo='bar')) AND (color!='red')"
is_deeply(
    $rdbo,
    [   'AND' => [
            'OR'    => [ 'name' => 'john', 'foo' => 'bar' ],
            'color' => { '!='   => 'red' },
        ]
    ],
    "query4 values"
);

ok( my $parser2 = Search::QueryParser::SQL->new(
        columns => [qw( first_name last_name email )],
    ),
    "parser2"
);

ok( my $query5 = $parser2->parse("joe smith"), "query5" );
$rdbo = $query5->rdbo;

#warn dump $rdbo;

#"(email='joe' OR first_name='joe' OR last_name='joe') \
# OR (email='smith' OR first_name='smith' OR last_name='smith')",
is_deeply(
    $rdbo,
    [   'OR' => [
            'OR',
            [ "email" => "joe", "first_name" => "joe", "last_name" => "joe" ],
            'OR',
            [   "email"      => "smith",
                "first_name" => "smith",
                "last_name"  => "smith"
            ],
        ]
    ],
    "query5 values"
);

ok( my $query6 = $parser2->parse('"joe smith"'), "query6" );
$rdbo = $query6->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   'OR',
        [   "email"      => "joe smith",
            "first_name" => "joe smith",
            "last_name"  => "joe smith",
        ],
    ],
    "query6 values"
);

ok( my $parser3 = Search::QueryParser::SQL->new(
        columns => [qw( category type title )]
    ),
    "parser3"
);

ok( my $query7
        = $parser3->parse( "
    category = (sports OR science)
      AND
    type = news
      AND
    (title = *million* OR title = *resident*)
    ", 1 ),
    "parse query7"
);

$rdbo = $query7->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   'AND' => [
            'OR' => [
                category => 'sports',
                category => 'science',
            ],
            type => 'news',
            'OR' => [
                title => { 'ILIKE' => '%million%' },
                title => { 'ILIKE' => '%resident%' },
            ]
        ]
    ],
    "query7 string"
);

ok( my $query8 = $parser3->parse(
        "category:(sports and food) OR title:(gold* and silver*)", 1
    ),
    "parse query8"
);

$rdbo = $query8->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   'OR' => [
            'AND' => [
                category => 'sports',
                category => 'food',
            ],
            'AND' => [
                title => { 'ILIKE' => 'gold%' },
                title => { 'ILIKE' => 'silver%' },
            ]
        ]
    ],
    "query8 string"
);

ok( my $parser4 = Search::QueryParser::SQL->new(
        columns => {
            foo => 'char',
            bar => 'int',
            dt  => 'datetime'
        }
    ),
    "parser4"
);

ok( my $parser4_query = $parser4->parse(
        "foo = red* and bar = 123* and dt = 2009-01-01*", 1
    ),
    "parse query7"
);

$rdbo = $parser4_query->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   "AND",
        [   "foo", { ILIKE => "red%" },
            "bar", { ">="  => 123 },
            "dt",  { ">="  => "2009-01-01" },
        ],
    ],
    "parser4_query string"
);

# lower
ok( my $lower_parser = Search::QueryParser::SQL->new(
        columns => {
            foo => 'char',
            bar => 'int',
            dt  => 'datetime'
        },
        lower => 1,
    ),
    "lower_parser"
);

ok( my $lower_query = $lower_parser->parse(
        "foo = red* and bar = 123* and dt = 2009-01-01*", 1
    ),
    "parse lower_query"
);

$rdbo = $lower_query->rdbo;

#warn dump $rdbo;
is_deeply(
    $rdbo,
    [   "AND",
        [   [ \'lower(foo) ILIKE lower(?)' => 'red%', ],
            "bar" => { ">=" => 123 },
            "dt"  => { ">=" => "2009-01-01" },
        ],
    ],
    "lower_query string"
);

###################
## dbic
## see https://rt.cpan.org/Ticket/Display.html?id=87287
##
ok( my $dbic_qp = Search::QueryParser::SQL->new(
        columns  => [ 'table1.column1', 'table1.column2' ],
        like     => 'LIKE',
        fuzzify2 => 1,
    ),
    "dbic_qp"
);
ok( my $dbic_query = $dbic_qp->parse( "butter -milk", 0 ),
    "parse dbic query" );

#diag( dump $dbic_query->dbic );
#diag( $dbic_query->stringify );
is_deeply(
    $dbic_query->dbic,
    [   '-and' => [
            "-or",
            [   "table1.column1", { LIKE => "%butter%" },
                "table1.column2", { LIKE => "%butter%" },
            ],
            "-and",
            [   "table1.column1", { "NOT LIKE" => "%milk%" },
                "table1.column2", { "NOT LIKE" => "%milk%" },
            ],
        ],

    ],
    "->dbic structure"
);

# lower feature
ok( my $lower_dbic_qp = Search::QueryParser::SQL->new(
        columns  => [ 'table1.column1', 'table1.column2' ],
        like     => 'LIKE',
        fuzzify2 => 1,
        lower    => 1,
    ),
    "lower_dbic_qp"
);
ok( my $lower_dbic_query = $lower_dbic_qp->parse( "butter -milk", 0 ),
    "parse lower dbic query" );

#diag( dump $lower_dbic_query->dbic );
#diag( $lower_dbic_query->stringify );
my $expected_lower = [
    '-and' => [
        "-or" => [
            [ \"lower(table1.column1) LIKE lower(?)", '%butter%', ],
            [ \"lower(table1.column2) LIKE lower(?)", '%butter%', ]
        ],
        "-and" => [
            [ \"lower(table1.column1) NOT LIKE lower(?)", '%milk%', ],
            [ \"lower(table1.column2) NOT LIKE lower(?)", '%milk%' ],
        ],
    ],

];
#diag( dump $expected_lower );
is_deeply( $lower_dbic_query->dbic,
    $expected_lower, "lower ->dbic structure" );
