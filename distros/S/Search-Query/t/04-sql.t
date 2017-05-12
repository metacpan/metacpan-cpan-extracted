#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 40;
use Data::Dump qw( dump );

use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields =>
            [ qw( foo color name ), { 'name' => 'num', type => 'int' } ],
        default_field  => 'name',
        dialect        => 'SQL',
        croak_on_error => 1,
    ),
    "new parser"
);

#dump $parser;

ok( my $query1 = $parser->parse('foo=bar'), "query1" );

cmp_ok( $query1, 'eq', "foo='bar'", "query1 string" );

ok( my $query2 = $parser->parse('foo:bar'), "query2" );

cmp_ok( $query2, 'eq', "foo='bar'", "query2 string" );

ok( my $query3 = $parser->parse('foo bar'), "query3" );

cmp_ok( $query3, 'eq', "name='foo' AND name='bar'", "query3 string" );

my $str = '-color:red (name:john OR foo:bar)';

# parse range
ok( my $rangeq = $parser->parse('bar and (-num=(1..5))'), "parse range" );
is( $rangeq,
    qq/name='bar' AND (num NOT IN ( 1, 2, 3, 4, 5 ))/,
    "stringify range"
);
ok( $rangeq = $parser->parse(qq/num=(1..5)/), "parse simple range" );
is( $rangeq, qq/num IN (1, 2, 3, 4, 5)/, "stringify simple range" );

ok( my $query4 = $parser->parse($str), "query4" );

cmp_ok(
    $query4, 'eq',
    "(name='john' OR foo='bar') AND color!='red'",
    "query4 string"
);

ok( my $parser2 = Search::Query::Parser->new(
        fields         => [qw( first_name last_name email )],
        dialect        => 'SQL',
        croak_on_error => 1,
        default_boolop => '',
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

ok( my $parser3 = Search::Query::Parser->new(
        fields           => [qw( foo bar )],
        query_class_opts => { quote_fields => '`', },
        dialect          => 'SQL',
        croak_on_error   => 1,
    ),
    "parser3"
);

ok( my $query7 = $parser3->parse('green'), "query7" );

cmp_ok( $query7, 'eq', "(`bar`='green' OR `foo`='green')", "query7 string" );

ok( my $parser4 = Search::Query::Parser->new(
        fields         => [qw( foo )],
        dialect        => 'SQL',
        croak_on_error => 1,
    ),
    "strict parser4"
);

eval { $parser4->parse('bar=123') };
my $errstr = $@;
ok( $errstr, "croak on invalid query" );
like( $errstr, qr/No such field: bar/, "caught exception we expected" );

ok( my $parser5 = Search::Query::Parser->new(
        fields => {
            foo => { type => 'char' },
            bar => { type => 'int' },
        },
        dialect          => 'SQL',
        query_class_opts => {
            like    => 'like',
            fuzzify => 1,
        },
        croak_on_error => 1,
    ),
    "parser5"
);

ok( my $query8 = $parser5->parse('foo:bar'), "query8" );

cmp_ok( $query8, 'eq', "foo like 'bar%'", "query8 string" );

ok( $query8 = $parser5->parse('bar=1*'), "query8 fuzzy int with wildcard" );

cmp_ok( $query8, 'eq', "bar>=1", "query8 fuzzy int with wildcard string" );

ok( $query8 = $parser5->parse('bar=1'), "query8 fuzzy int no wildcard" );

cmp_ok( $query8, 'eq', "bar>=1", "query8 fuzzy int no wildcard string" );

ok( my $parser6 = Search::Query::Parser->new(
        fields           => [qw( foo )],
        dialect          => 'SQL',
        query_class_opts => {
            like     => 'like',
            fuzzify2 => 1,
        },
        croak_on_error => 1,
    ),
    "parser6"
);

ok( my $query9 = $parser6->parse('foo:bar'), "query9" );

cmp_ok( $query9, 'eq', "foo like '%bar%'", "query9 string" );

################
# null query

ok( my $null_parser = Search::Query::Parser->new(
        dialect          => 'SQL',
        null_term        => 'NULL',
        default_boolop   => '',
        query_class_opts => { default_field => [qw( color )] },
        fields           => [qw( color )],
    ),
    "null_parser"
);

ok( my $null_query = $null_parser->parse('color=NULL'), "parse color=NULL" );
is( $null_query, "color is NULL", "null query stringified" );

#diag($null_query);
#diag( dump $null_query );

ok( my $not_null_query = $null_parser->parse('color!=NULL'),
    "parser color!=NULL" );
is( $not_null_query, "color is not NULL", "not null query stringified" );

