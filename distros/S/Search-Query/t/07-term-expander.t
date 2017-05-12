#!/usr/bin/env perl 
use strict;
use warnings;
use Search::Query;
use Test::More tests => 5;

ok( my $parser1 = Search::Query->parser(
        term_expander => sub {
            my ($term) = @_;
            return ( qw( one two three ), $term );
        }
    ),
    "new parser with term_expander"
);

ok( my $query1 = $parser1->parse("foo=bar"), "parse foo=bar" );
my $expect1 = qq/+(foo=one foo=two foo=three foo=bar)/;
is( "$query1", $expect1, "query expanded" );

my $parser2 = Search::Query->parser(
    term_expander => sub {
        my ($term, $field) = @_;
        if ($field) {
            return "$term-$field";
        }
        else {
            return "$term";
        }
    }
);

my $query2 = $parser2->parse('foo=bar');
is( "$query2", qq/+foo=bar-foo/, "query expanded, with field passed" );

my $query3 = $parser2->parse('bar');
is( "$query3", qq/+bar/, "query expanded, with field passed" );
