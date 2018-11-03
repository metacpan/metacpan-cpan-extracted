#!/usr/bin/env perl

use v5.20;

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC::FilterUtils qw(parser);

#use Data::Printer;

my %tests = (
    "Price mod 2 eq 0"                                         =>
        {
            operator =>   "eq",
            subject  =>  {
                operator =>  "mod",
                subject  =>  "Price",
                value    =>  2,
            },
            value => 0,
        },
    "Price div 2 gt 4"                                         =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "div",
                subject  =>  "Price",
                value    =>  2,
            },
            value => 4,
        },
    "Price mul 2 gt 2000"                                      =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "mul",
                subject  =>  "Price",
                value    =>  2,
            },
            value => 2000,
        },
    "Price sub 5 gt 10"                                        =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "sub",
                subject  =>  "Price",
                value    =>  5,
            },
            value => 10,
        },
    "Price add 5 gt 10"                                        => 
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "add",
                subject  =>  "Price",
                value    =>  5,
            },
            value => 10,
        },
    "Price le 3.5 or Price gt 200"                             =>
        {
            operator =>   "or",
            subject  =>  {
                operator =>  "le",
                subject  =>  "Price",
                value    =>  3.5,
            },
            value =>     {
                operator =>  "gt",
                subject  =>  "Price",
                value    =>  200,
            }
        },
    "Price le 200 and Price gt 3.5"                            =>
        {
            operator =>   "and",
            subject  =>  {
                operator =>  "le",
                subject  =>  "Price",
                value    =>  200,
            },
            value =>     {
                operator =>  "gt",
                subject  =>  "Price",
                value    =>  3.5,
            }
        },
    "Price le 100"                                             =>
        {
            operator =>  "le",
            subject  =>  "Price",
            value    =>  100,
        },
    "Price lt 20"                                              =>
        {
            operator =>  "lt",
            subject  =>  "Price",
            value    =>  20
        },
    "Price ge 10"                                              =>
        {
            operator =>  "ge",
            subject  =>  "Price",
            value    =>  10
        },
    "Price gt 20"                                              =>
        {
            operator =>  "gt",
            subject  =>  "Price",
            value    =>  20
        },
    "Address/City ne 'London'"                                 =>
        {
            operator =>  "ne",
            subject  =>  "Address/City",
            value    =>  "'London'",
        },
    "Address/City eq 'Redmond'"                                =>
        {
            operator =>  "eq",
            subject  =>  "Address/City",
            value    =>  "'Redmond'",
        },
    "substringof('Alfreds', CompanyName) eq true"  =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "substringof",
                subject  =>  "Alfreds",
                value    =>  "CompanyName"
            },
            value =>     "true"
        },
    "endswith(CompanyName, 'Futterkiste') eq true" =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "endsWith",
                subject  =>  "CompanyName",
                value    =>  "Futterkiste"
            },
            value =>     "true"
        },
    "startswith(CompanyName, 'Alfr') eq true"      =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "startsWith",
                subject  =>  "CompanyName",
                value    =>  "Alfr"
            },
            value =>     "true"
        },
    "((name eq 'Serena') and (age lt 5))" =>
        {
            operator =>  "and",
            subject  =>   {
                operator =>  "eq",
                subject  =>  "name",
                value    =>  "'Serena'"
            },
            value =>     {
                operator =>  "lt",
                subject  =>  "age",
                value    =>  5,
            }
        },
    "(Price sub 5) gt 10" =>
        {
            operator =>  "gt",
            subject  =>   {
                operator =>  "sub",
                subject  =>  "Price",
                value    =>  5
            },
            value => 10,
        },
);


for my $filter ( sort keys %tests ) {
    my $vars = parser->( $filter );
    #p $vars;
    is_deeply $vars, $tests{$filter}, $filter;
}

done_testing();
