#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

is $es->count( query => { term => { text => 'foo' } } )->{count}, 17,
    "Count: query";

is $es->count( term => { text => 'foo' } )->{count}, 17, "Count: term";

is $es->count( terms => { text => [ 'foo', 'bar' ] } )->{count}, 25,
    "Count: terms";
is $es->count( in => { text => [ 'foo', 'bar' ] } )->{count}, 25, "Count: in";

is $es->count( range => { num => { gte => 10, lte => 20 } } )->{count}, 11,
    'Count: range';

is $es->count( range => { num => { gt => 10, lt => 20 } } )->{count}, 9,
    'Count: range, gt/lt';

is $es->count( prefix => { text => 'ba' } )->{count}, 24, 'Count: prefix';

is $es->count( wildcard => { text => 'ba?' } )->{count}, 24,
    'Count: wildcard';

is $es->count( match_all => {} )->{count}, 29, 'Count: match_all';

is $es->count()->{count}, 29, 'Count: match_all, implicitly ';

is $es->count(
    query_string => {
        query         => 'foo AND bar AND -baz',
        default_field => 'text'
    }
    )->{count}, 4,
    'Count: query_string';

is $es->count(
    bool => {
        must =>
            [ { term => { text => 'foo' } }, { term => { text => 'bar' } } ]
    }
    )->{count}, 8,
    'Count: bool';

is $es->count(
    dis_max => {
        queries =>
            [ { term => { text => 'foo' } }, { term => { text => 'bar' } } ]
    }
    )->{count}, 25,
    'Count: dis_max';

is $es->count(
    constant_score => { filter => { terms => { text => [ 'foo', 'bar' ] } } }
    )->{count}, 25,
    'Count: constant_score';

is $es->count(
    filtered => {
        query  => { term => { text => 'foo' } },
        filter => { term => { text => 'bar' } }
    }
    )->{count}, 8,
    'Count: filtered';

is $es->count( field => { text => 'foo' } )->{count}, 17, 'Count: field';

is $es->count(
    fuzzy => {
        text => {
            value          => 'bart',
            prefix_length  => 1,
            min_similarity => 0.2
        }
    }
)->{count}, 24, 'Count: fuzzy';

is $es->count( flt => { fields => ['text'], like_text => 'bat' } )->{count},
    24,
    'Count: fuzzy_like_this';

is $es->count( flt_field => { text => { like_text => 'fooo' } } )->{count},
    17,
    'Count: fuzzy_like_this_field';

is $es->count(
    mlt => {
        like_text     => 'foo bar baz',
        min_term_freq => 1,
        min_doc_freq  => 1
    }
    )->{count}, 29,
    'Count: more_like_this';

is $es->count(
    mlt_field => {
        text => {
            like_text     => 'foo bar baz',
            min_term_freq => 1,
            min_doc_freq  => 1
        }
    }
    )->{count}, 29,
    'Count: more_like_this';

is $es->count(
    span_first => {
        match => {
            span_near => {
                clauses => [
                    { span_term => { text => 'baz' } },
                    { span_term => { text => 'bar' } }
                ],
                slop     => 0,
                in_order => 0
            }
        },
        end => 2
    }
)->{count}, 4, 'Count: span queries';

TODO: {
    local $TODO = "field_masking_span queries not recognised by server";
    is $es->count(
        field_masking_span => {
            field => 'num',
            query => { span_term => { text => 'foo' } }
        }
    )->{count}, 1111, 'Count: field_masking_span';
}

1
