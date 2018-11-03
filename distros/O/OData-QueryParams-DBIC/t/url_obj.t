#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC;
use Mojo::URL;

my %tests = (
    "filter=Price le 3.5 or Price gt 200"                             => { -or  => [ { Price => { '<=' => 3.5 } }, { Price => { '>' => 200 } } ] },
    "filter=Price le 200 and Price gt 3.5"                            => { -and => [ { Price => { '<=' => 200 } }, { Price => { '>' => 3.5 } } ] },
    "filter=Price le 100"                                             => { Price => { '<=' => 100 } },
    "filter=Price lt 20"                                              => { Price => { '<' => 20 } },
    "filter=Price ge 10"                                              => { Price => { '>=' => 10 } },
    "filter=Price gt 20"                                              => { Price => { '>' => 20 } },
    "filter=Address/City ne 'London'"                                 => { 'Address.City' => { '!=' => 'London' } },
    "filter=Address/City eq 'Redmond'"                                => { 'Address.City' => { '==' => 'Redmond' } },
    "filter=((name eq 'Serena') and (age lt 5))"                      => { -and => [ { name => { '==' => 'Serena' } }, { age => { '<' => 5 } } ] },

    'top=10' => { rows => 10 },
    'top=3'  => { rows => 3 },

    'select=col1'        => { columns => ['col1'] },
    'select=col1,col2'   => { columns => ['col1','col2'] },
    'select=col1 ,col2'  => { columns => ['col1','col2'] },
    'select=col1, col2'  => { columns => ['col1','col2'] },
    'select=col1 , col2' => { columns => ['col1','col2'] },

    'skip=10' => { page => 11 },
    'skip=3'  => { page => 4 },

    'skip=10&top=3' => { rows => 3, page => 11 },
    'skip=3&top=10' => { rows => 10, page => 4 },

    'skip=10&top=3&select=col1'      => { rows => 3, page => 11, columns => ['col1'] },
    'skip=3&top=10&select=col1,col2' => { rows => 10, page => 4, columns => ['col1','col2'] },

    'skip=10&top=3&filter=Price lt 20'              => [{ Price => { '<' => 20 } },                 { rows => 3, page => 11 } ],
    "skip=3&top=10&filter=Address/City ne 'London'" => [{ 'Address.City' => { '!=' => 'London' } }, { rows => 10, page => 4 } ],
);

for my $query_string ( sort keys %tests ) {
    my $expected  = $tests{$query_string};
    my $param_obj = Mojo::Parameters->new( $query_string );

    my ($where,$opts) = params_to_dbic( $param_obj );

    if ( 'ARRAY' eq ref $expected ) {
        is_deeply [$where,$opts], $tests{$query_string}, 'Query: ' . $query_string;
    }
    elsif ( $query_string =~ m{\Afilter=} ) {
        is_deeply $where, $tests{$query_string}, 'Query: ' . $query_string;
    }
    else {
        is_deeply $opts, $tests{$query_string}, 'Query: ' . $query_string;
    }
}

done_testing();

