use strict;
use warnings;
use Test::More;
use Test::DBIx::Class qw(:resultsets);
use Search::Query;

use Data::Dumper::Concise;

fixtures_ok 'core' => 'installed the core fixtures from configuration files';

ok( my $parser = Search::Query->parser(
        dialect        => 'DBIxClass',
        default_field  => [qw( name email )],
        croak_on_error => 1,

    ),
    'Search::Query::Parser constructed ok'
);

{
    my $rs_query    = Person->search_rs( $parser->parse('o')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        [   \[ "LOWER(name) LIKE ?",  [ plain_value => "%o%" ] ],
            \[ "LOWER(email) LIKE ?", [ plain_value => "%o%" ] ],
        ]
    );
    eq_resultset( $rs_query, $rs_expected,
        'one term, default fields, included' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('email:.com')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        \[ "LOWER(email) LIKE ?", [ plain_value => "%.com%" ] ] );
    eq_resultset( $rs_query, $rs_expected, 'one term, one field, included' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age=31')->as_dbic_query );
    my $rs_expected = Person->search_rs( { age => 31 } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, exact match' );
}

{
    my $rs_query = Person->search_rs( $parser->parse('!n')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        [   \[  "COALESCE( LOWER(name), '' ) NOT LIKE ?",
                [ plain_value => "%n%" ]
            ],
            \[  "COALESCE( LOWER(email), '' ) NOT LIKE ?",
                [ plain_value => "%n%" ]
            ],
        ]
    );
    eq_resultset( $rs_query, $rs_expected,
        'one term, default fields, excluded' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('alex home')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        {   '-and' => [
                [   \[ "LOWER(name) LIKE ?", [ plain_value => "%alex%" ] ],
                    \[  "LOWER(email) LIKE ?", [ plain_value => "%alex%" ]
                    ],
                ],
                [   \[ "LOWER(name) LIKE ?", [ plain_value => "%home%" ] ],
                    \[  "LOWER(email) LIKE ?", [ plain_value => "%home%" ]
                    ],
                ]
            ]
        }
    );
    eq_resultset( $rs_query, $rs_expected,
        'two terms, default fields, included' );
}

{
    my $rs_query =
        Person->search_rs(
        $parser->parse('email:alex email:work')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        {   '-and' => [
                \[ "LOWER(email) LIKE ?", [ plain_value => "%alex%" ] ],
                \[ "LOWER(email) LIKE ?", [ plain_value => "%work%" ] ],
            ]
        }
    );
    eq_resultset( $rs_query, $rs_expected, 'two terms, one field, included' );
}

{
    my $rs_query = Person->search_rs(
        $parser->parse('email!~alex email!~work')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        {   '-and' => [
                \[  "COALESCE( LOWER(email), '' ) NOT LIKE ?",
                    [ plain_value => "%alex%" ]
                ],
                \[  "COALESCE( LOWER(email), '') NOT LIKE ?",
                    [ plain_value => "%work%" ]
                ],
            ]
        }
    );
    eq_resultset( $rs_query, $rs_expected, 'two terms, one field, excluded' );
}

{
    my $rs_query =
        Person->search_rs(
        $parser->parse('age=31 email:work.org')->as_dbic_query );
    my $rs_expected = Person->search_rs(
        {   '-and' => [
                { age => 31 },
                \[  "LOWER(email) LIKE ?", [ plain_value => "%work.org%" ]
                ],
            ]
        }
    );
    eq_resultset( $rs_query, $rs_expected,
        'two terms, two fields, exact & included' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age>30')->as_dbic_query );
    my $rs_expected = Person->search_rs( { age => { '>' => 30 } } );
    eq_resultset( $rs_query, $rs_expected, 'one term, one field, larger' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age<35')->as_dbic_query );
    my $rs_expected = Person->search_rs( { age => { '<' => 35 } } );
    eq_resultset( $rs_query, $rs_expected, 'one term, one field, smaller' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age>=31')->as_dbic_query );
    my $rs_expected = Person->search_rs( { age => { '>=' => 31 } } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, larger and equal' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age<=31')->as_dbic_query );
    my $rs_expected = Person->search_rs( { age => { '<=' => 31 } } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, smaller and equal' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age#31,38')->as_dbic_query );
    my $rs_expected =
        Person->search_rs( { age => { -in => [qw( 31 38 )] } } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, list of values' );
}

{
    my $rs_query =
        Person->search_rs( $parser->parse('age!#31,38')->as_dbic_query );
    my $rs_expected =
        Person->search_rs( { age => { -not_in => [qw( 31 38 )] } } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, not in list of values' );
}

{
    my $rs_query =
        Person->search_rs(
        $parser->parse('not (age!#31,38)')->as_dbic_query );
    my $rs_expected =
        Person->search_rs( { age => { -in => [qw( 31 38 )] } } );
    eq_resultset( $rs_query, $rs_expected,
        'one term, one field, negated not in list of values' );
}

done_testing;
