#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 19;

use_ok('Search::Query');

ok( my $parser = Search::Query->parser(
        fields => {
            field1 => { alias_for => 'field2', },
            field2 => {

            },
            field3    => { alias_for => [qw( field2 mydefault )], },
            mydefault => {

            },
        },
        default_field => 'mydefault'
    ),
    "new parser"
);

my %queries = (

    'hello world' => '+mydefault:hello +mydefault:world',
    'field2=foo'  => '+field2=foo',
    'field1:foo'  => '+field2:foo',
    'field3:foo or field1=(green or blue)' =>
        '(field2:foo mydefault:foo) (field2=green field2=blue)',

);

for my $string ( sort keys %queries ) {

    ok( my $query = $parser->parse($string), "parse $string" );
    is( $query, $queries{$string}, "string cmp" );

}

# parser with default_field => ARRAY
ok( $parser = Search::Query->parser(
        fields => {
            field1 => { alias_for => 'field2', },
            field2 => {

            },
            field3    => { alias_for => [qw( field2 mydefault )], },
            mydefault => {

            },
        },
        default_field => [qw/mydefault field1/],
    ),
    "new array default_field parser"
);

# expect default_field expansion differently with array
$queries{'hello world'}
    = '+(mydefault:hello field2:hello) +(mydefault:world field2:world)';

for my $string ( sort keys %queries ) {

    ok( my $query = $parser->parse($string), "parse $string" );
    is( $query, $queries{$string}, "string cmp" );

}
