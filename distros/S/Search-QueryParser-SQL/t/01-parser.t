#!/usr/bin/env perl
use strict;
use Test::More tests => 33;

use_ok('Search::QueryParser::SQL');

ok( my $parser = Search::QueryParser::SQL->new(
        columns        => [qw( foo color name )],
        default_column => 'name'
    ),
    "new parser"
);

ok( my $query1 = $parser->parse('foo=bar'), "query1" );

cmp_ok( $query1, 'eq', "foo='bar'", "query1 string" );

ok( my $query2 = $parser->parse('foo:bar'), "query2" );

cmp_ok( $query2, 'eq', "foo='bar'", "query2 string" );

ok( my $query3 = $parser->parse( 'foo bar', 1 ), "query3" );

cmp_ok( $query3, 'eq', "name='foo' AND name='bar'", "query3 string" );

ok( my $query4 = $parser->parse('-color:red (name:john OR foo:bar)'),
    "query4" );

cmp_ok(
    $query4, 'eq',
    "(name='john' OR foo='bar') AND color!='red'",
    "query4 string"
);

ok( my $parser2 = Search::QueryParser::SQL->new(
        columns => [qw( first_name last_name email )],
    ),
    "parser2"
);

ok( my $query5 = $parser2->parse("joe smith"), "query5" );

cmp_ok(
    $query5,
    'eq',
    "(email='joe' OR first_name='joe' OR last_name='joe') OR (email='smith' OR first_name='smith' OR last_name='smith')",
    "query5 string"
);

ok( my $query6 = $parser2->parse('"joe smith"'), "query6" );

cmp_ok(
    $query6,
    'eq',
    "(email='joe smith' OR first_name='joe smith' OR last_name='joe smith')",
    "query6 string"
);

ok( my $parser3 = Search::QueryParser::SQL->new(
        columns       => [qw( foo bar )],
        quote_columns => '`',
    ),
    "parser3"
);

ok( my $query7 = $parser3->parse('green'), "query7" );

cmp_ok( $query7, 'eq', "(`bar`='green' OR `foo`='green')", "query7 string" );

ok( my $parser4 = Search::QueryParser::SQL->new(
        columns => [qw( foo )],
        strict  => 1,
    ),
    "strict parser4"
);

eval { $parser4->parse('bar=123') };

ok( $@ && $@ =~ m/^invalid column name: bar/, "croak on invalid query" );

ok( my $parser5 = Search::QueryParser::SQL->new(
        columns => { foo => 'char', bar => 'int' },
        like    => 'like',
        fuzzify => 1,
        strict  => 1
    ),
    "parser5"
);

ok( my $query8 = $parser5->parse('foo:bar'), "query8" );

cmp_ok( $query8, 'eq', "foo like 'bar%'", "query8 string" );

ok( $query8 = $parser5->parse('bar=1*'), "query8 fuzzy int with wildcard" );

cmp_ok( $query8, 'eq', "bar>=1", "query8 fuzzy int with wildcard string" );

ok( $query8 = $parser5->parse('bar=1'), "query8 fuzzy int no wildcard" );

cmp_ok( $query8, 'eq', "bar>=1", "query8 fuzzy int no wildcard string" );

ok( my $parser6 = Search::QueryParser::SQL->new(
        columns  => [qw( foo )],
        like     => 'like',
        fuzzify2 => 1,
        strict   => 1
    ),
    "parser6"
);

ok( my $query9 = $parser6->parse('foo:bar'), "query9" );

cmp_ok( $query9, 'eq', "foo like '%bar%'", "query9 string" );

# test lower feature
ok( my $parser7 = Search::QueryParser::SQL->new(
        columns  => [qw( foo )],
        lower    => 1,
        like     => 'like',
        fuzzify2 => 1,
        strict   => 1
    ),  
    "parser7"
);

ok( my $query10 = $parser7->parse('foo:bar'), "query10" );

cmp_ok( $query10, 'eq', "lower(foo) like lower('%bar%')", "query10 string" );

