#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 75;
use Data::Dump qw( dump );

use Lucy::Analysis::PolyAnalyzer;
my $analyzer = Lucy::Analysis::PolyAnalyzer->new( language => 'en', );

use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields => {
            foo   => { analyzer => $analyzer },
            color => { analyzer => $analyzer },
            name  => { analyzer => $analyzer },
        },
        default_field  => 'name',
        dialect        => 'Lucy',
        croak_on_error => 1,
    ),
    "new parser"
);

#dump $parser;

ok( my $query1 = $parser->parse('foo=BAR'), "query1" );

is( $query1, qq/foo:BAR/, "query1 string" );

ok( my $ks_query1 = $query1->as_lucy_query(), "as_lucy_query" );
ok( $ks_query1->isa('Lucy::Search::TermQuery'),
    "ks_query isa TermQuery" );
is( $ks_query1->to_string, "foo:bar", "KS query analyzer applied" );

ok( my $query2 = $parser->parse('foo:BaR'), "query2" );

is( $query2, qq/foo:BaR/, "query2 string" );

ok( my $query3 = $parser->parse('FoO bar'), "query3" );

is( $query3, qq/name:FoO AND name:bar/, "query3 string" );

my $str = '-color:red (name:john OR foo:bar)';

ok( my $query4 = $parser->parse($str), "query4" );

#dump $query4;

is( $query4, qq/(name:john OR foo:bar) AND (NOT color:red)/,
    "query4 string" );

ok( my $parser2 = Search::Query::Parser->new(
        fields         => [qw( first_name last_name email )],
        dialect        => 'Lucy',
        croak_on_error => 1,
        default_boolop => '',
    ),
    "parser2"
);

ok( my $query5 = $parser2->parse("joe smith"), "query5" );

is( $query5, qq/joe OR smith/, "query5 string" );

ok( my $query6 = $parser2->parse(qq/"joe smith"/), "query6" );

is( $query6, qq/"joe smith"/, "query6 string" );

ok( my $parser3 = Search::Query::Parser->new(
        fields         => [qw( foo bar )],
        dialect        => 'Lucy',
        croak_on_error => 1,
    ),
    "parser3"
);

ok( my $query7 = $parser3->parse('green'), "query7" );

is( $query7, qq/green/, "query7 string" );

ok( my $gardenq = $parser3->parse('(garden) AND (-foo=(20100208..20100309))'),
    "parse complex garden query with range"
);

#dump $gardenq;

is( $gardenq,
    qq/(garden) AND (foo!:(20100208..20100309))/,
    "parsed garden query"
);

ok( my $parser4 = Search::Query::Parser->new(
        fields         => [qw( foo )],
        dialect        => 'Lucy',
        croak_on_error => 1,
    ),
    "strict parser4"
);

eval { $parser4->parse('bar=123') };
my $errstr = $@;
ok( $errstr, "croak on invalid query" );
like( $errstr, qr/No such field: bar/, "caught exception we expected" );

ok( my $round_trip_not = $parser4->parse('NOT foo:bar'),
    "parse NOT foo:bar" );
ok( my $round_trip_not2 = $parser4->parse('foo!=bar'), "parse foo!=bar" );
is( "$round_trip_not", "$round_trip_not2", "not round trips" );
is( $round_trip_not2,  qq/(NOT foo:bar)/,  "!= to NOT :" );

ok( my $parser5 = Search::Query::Parser->new(
        fields => {
            foo => { type => 'char' },
            bar => { type => 'int' },
        },
        dialect          => 'Lucy',
        query_class_opts => { fuzzify => 1, },
        croak_on_error   => 1,
    ),
    "parser5"
);

ok( my $query8 = $parser5->parse('foo:bar'), "query8" );
is( $query8, qq/foo:bar*/, "query8 string" );
ok( $query8 = $parser5->parse('bar:1*'), "query8 fuzzy int with wildcard" );
is( $query8, qq/bar:1*/, "query8 fuzzy int with wildcard string" );
ok( $query8 = $parser5->parse('bar=1'), "query8 fuzzy int no wildcard" );
is( $query8, qq/bar:1*/, "query8 fuzzy int no wildcard string" );

ok( my $parser6 = Search::Query::Parser->new(
        fields           => [qw( foo )],
        dialect          => 'Lucy',
        query_class_opts => { fuzzify => 1, },
        croak_on_error   => 1,
    ),
    "parser6"
);

ok( my $query9 = $parser6->parse('foo:bar'), "query9" );

is( $query9, qq/foo:bar*/, "query9 string" );

# range expansion
ok( my $range_parser = Search::Query::Parser->new(
        dialect       => 'Lucy',
        fields        => [qw( date swishdefault )],
        default_field => 'swishdefault',
    ),
    "range_parser"
);

ok( my $range_query = $range_parser->parse("date=(1..10)"), "parse range" );

#dump $range_query;

is( $range_query, qq/date:(1..10)/, "range expanded" );

ok( my $range_not_query = $range_parser->parse("-(date=( 1..3 ))"),
    "parse !range" );

#dump $range_not_query;
is( $range_not_query, qq/(NOT (date:(1..3)))/, "!range expanded" );

# operators
ok( my $or_pipe_query = $range_parser->parse("date:( 1 | 2 )"),
    "parse piped OR" );

#dump $or_pipe_query;
is( $or_pipe_query, qq/(date:1 OR date:2)/, "or_pipe_query $or_pipe_query" );

ok( my $and_amp_query = $range_parser->parse("date:( 1 & 2 )"),
    "parse ampersand AND" );

is( $and_amp_query, qq/(date:1 AND date:2)/, "and_amp_query $and_amp_query" );

ok( my $not_bang_query = $range_parser->parse(qq/! date:("1 3" | 2)/),
    "parse bang NOT" );

#dump $not_bang_query;

is( $not_bang_query,
    qq/(NOT (date:"1 3" OR date:2))/,
    "not_bang_query $not_bang_query"
);

# double negative
ok( my $dbl_neg_query
        = $range_parser->parse(qq/(bar) and (-date=123 -date=456)/),
    "parse double negative query"
);

is( $dbl_neg_query,
    qq/(swishdefault:bar) AND ((NOT date:123) (NOT date:456))/,
    "double negative query stringify"
);

ok( my $parser_alias_for = Search::Query->parser(
        fields => {
            field1 => { alias_for => 'field2', },
            field2 => 1,
        },
        dialect => 'Lucy',
    ),
    "new parser2"
);

ok( my $query_alias_for = $parser_alias_for->parse('field1=foo'),
    "parse alias_for with no default field" );
is( $query_alias_for, qq/field2:foo/, "straight up aliasing" );
ok( my $query_alias_for2 = $parser_alias_for->parse('foo'),
    "parse alias_for with no default field and no field specified"
);
is( $query_alias_for2, qq/foo/, "query expanded omits aliases" );

# wildcards
ok( my $fuzzy_parser = Search::Query->parser(
        dialect          => 'Lucy',
        croak_on_error   => 1,
        fields           => [qw( field1 )],
        query_class_opts => { default_field => 'field1' }
    ),
    "new fuzzy parser"
);
ok( my $fuzzy_query = $fuzzy_parser->parse('foo*'), "parse foo*" );
ok( my $fuzzy_ks    = $fuzzy_query->as_lucy_query,    "fuzzy as_lucy_query" );
is( $fuzzy_ks->to_string, $fuzzy_query->stringify,
    "stringification matches" );

# lone wildcards should croak
eval { my $lone_wildcard = $fuzzy_parser->parse(qq/foo * bar/); };
ok( $@, "lone_wildcard croaks" );

#diag($@);

# no fields defined
ok( my $nofields_parser = Search::Query->parser( dialect => 'Lucy', ),
    "nofields parser" );
ok( my $nofields_query = $nofields_parser->parse('foo'), "parse nofields" );
is( $nofields_query, "foo", "stringify nofields_query" );

# proximity
ok( my $proximity = $nofields_parser->parse(qq/"foo bar"~5/),
    "parse proximity phrase" );
is( $proximity, qq/"foo bar"~5/, "stringify proximity" );

# simple NOT
ok( my $simple_not = $nofields_parser->parse(qq/not foo/), "parse NOT foo" );
is( $simple_not, qq/NOT foo/, "stringify NOT foo" );

# complex NOT
ok( my $complex_not_parser = Search::Query->parser(
        fields  => [qw( one two three four five )],
        dialect => 'Lucy',
    ),
    "new complex not parser"
);

my $complex_str
    = qq/one!:(20100504..20100603) AND (two:"APMG") AND (NOT three:"MN") AND (NOT four:"INC_1") AND five:active/;
my $complex_ks
    = qq/(-one:[20100504 TO 20100603] AND two:"APMG" AND -three:"MN" AND -four:"INC_1" AND five:active)/;

ok( my $complex_not = $complex_not_parser->parse($complex_str),
    "parse complex NOT" );

is( $complex_str, $complex_not, "complex not query round-trip" );

#diag($complex_not);
#diag( dump $complex_not );

is( $complex_not->as_lucy_query()->to_string(),
    $complex_ks, "complex_not as KS string" );

####################################################
# bad query handling
my $bad_query = $nofields_parser->parse(qq/foo -- or bar/);
ok( $nofields_parser->error, "bad query yields error but not croak" );
