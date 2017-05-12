#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 51;
use Data::Dump qw( dump );

use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields         => [qw( foo color name )],
        default_field  => 'name',
        dialect        => 'SWISH',
        croak_on_error => 1,
    ),
    "new parser"
);

#dump $parser;

ok( my $query1 = $parser->parse('foo=bar'), "query1" );

is( $query1, qq/foo=bar/, "query1 string" );

ok( my $query2 = $parser->parse('foo:bar'), "query2" );

is( $query2, qq/foo=bar/, "query2 string" );

ok( my $query3 = $parser->parse('foo bar'), "query3" );

is( $query3, qq/name=foo AND name=bar/, "query3 string" );

my $str = '-color:red (name:john OR foo:bar)';

ok( my $query4 = $parser->parse($str), "query4" );

#dump $query4;

is( $query4, qq/(name=john OR foo=bar) NOT color=red/, "query4 string" );

ok( my $parser2 = Search::Query::Parser->new(
        fields         => [qw( first_name last_name email )],
        dialect        => 'SWISH',
        croak_on_error => 1,
        default_boolop => '',
    ),
    "parser2"
);

ok( my $query5 = $parser2->parse("joe smith"), "query5" );

is( $query5, qq/swishdefault=joe OR swishdefault=smith/, "query5 string" );

ok( my $query6 = $parser2->parse(qq/"joe smith"/), "query6" );

is( $query6, qq/swishdefault="joe smith"/, "query6 string" );

ok( my $parser3 = Search::Query::Parser->new(
        fields         => [qw( foo bar )],
        dialect        => 'SWISH',
        croak_on_error => 1,
    ),
    "parser3"
);

ok( my $query7 = $parser3->parse('green'), "query7" );

is( $query7, qq/swishdefault=green/, "query7 string" );

ok( my $parser4 = Search::Query::Parser->new(
        fields         => [qw( foo )],
        dialect        => 'SWISH',
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
        dialect          => 'SWISH',
        query_class_opts => { fuzzify => 1, },
        croak_on_error   => 1,
    ),
    "parser5"
);

ok( my $query8 = $parser5->parse('foo:bar'), "query8" );

is( $query8, qq/foo=bar*/, "query8 string" );

ok( $query8 = $parser5->parse('bar=1*'), "query8 fuzzy int with wildcard" );

is( $query8, qq/bar=1*/, "query8 fuzzy int with wildcard string" );

ok( $query8 = $parser5->parse('bar=1'), "query8 fuzzy int no wildcard" );

is( $query8, qq/bar=1*/, "query8 fuzzy int no wildcard string" );

ok( my $parser6 = Search::Query::Parser->new(
        fields           => [qw( foo )],
        dialect          => 'SWISH',
        query_class_opts => { fuzzify => 1, },
        croak_on_error   => 1,
    ),
    "parser6"
);

ok( my $query9 = $parser6->parse('foo:bar'), "query9" );

is( $query9, qq/foo=bar*/, "query9 string" );

# range expansion
ok( my $range_parser = Search::Query::Parser->new(
        dialect       => 'SWISH',
        fields        => [qw( date swishdefault )],
        default_field => 'swishdefault',
    ),
    "range_parser"
);

ok( my $range_query = $range_parser->parse("date=(1..10)"), "parse range" );

#dump $range_query;

is( $range_query,
    qq/date=(1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7 OR 8 OR 9 OR 10)/,
    "range expanded"
);

ok( my $range_not_query = $range_parser->parse("date!=( 1..3 )"),
    "parse !range" );

#dump $range_not_query;
is( $range_not_query, qq/NOT date=( 1 2 3 )/, "!range exanded" );

# operators
ok( my $or_pipe_query = $range_parser->parse("date=( 1 | 2 )"),
    "parse piped OR" );

#dump $or_pipe_query;
is( $or_pipe_query, qq/(date=1 OR date=2)/, "or_pipe_query $or_pipe_query" );

ok( my $and_amp_query = $range_parser->parse("date=( 1 & 2 )"),
    "parse ampersand AND" );

is( $and_amp_query, qq/(date=1 AND date=2)/, "and_amp_query $and_amp_query" );

ok( my $not_bang_query = $range_parser->parse(qq/! date=("1 3" | 2)/),
    "parse bang NOT" );

#dump $not_bang_query;

is( $not_bang_query,
    qq/NOT (date="1 3" OR date=2)/,
    "not_bang_query $not_bang_query"
);

###################
# proximity
ok( my $proximity_query = $range_parser->parse(qq/"foo bar"~5/),
    "parse proximity query" );
is( $proximity_query,
    qq/swishdefault=(foo NEAR5 bar)/,
    "proximity query stringifies to NEARn"
);
ok( $proximity_query = $range_parser->parse(qq/foo NEAR5 bar/),
    "parse NEAR proximity query" );
is( $proximity_query,
    qq/swishdefault=(foo NEAR5 bar)/,
    "proximity query stringifies to NEARn"
);

# double negative
ok( my $dbl_neg_query
        = $range_parser->parse(qq/(bar) and (-date=123 -date=456)/),
    "parse double negative query"
);

is( $dbl_neg_query,
    qq/(swishdefault=bar) AND (NOT date=123 NOT date=456)/,
    "double negative query stringify"
);

################
# null query

ok( my $null_parser = Search::Query::Parser->new(
        dialect          => 'SWISH',
        null_term        => 'NULL',
        default_boolop   => '',
        query_class_opts => { default_field => [qw( color )] },
        fields           => [qw( color )],
    ),
    "null_parser"
);

ok( my $null_query = $null_parser->parse('color=NULL'), "parse color=NULL" );
eval { $null_query->stringify(); };

#diag( $@);
like(
    $@,
    qr/does not support/,
    "stringifying a SWISH dialect with NULL will croak"
);
