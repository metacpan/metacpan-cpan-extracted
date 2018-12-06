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
                sub_type =>  "field",
                value    =>  2,
                val_type =>  'numeric',
            },
            value => 0,
            val_type => 'numeric',
            sub_type => undef,
        },
    "Price div 2 gt 4"                                         =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "div",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  2,
                val_type =>  'numeric',
            },
            value => 4,
            val_type => 'numeric',
            sub_type => undef,
        },
    "Price mul 2 gt 2000"                                      =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "mul",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  2,
                val_type =>  'numeric',
            },
            value => 2000,
            val_type => 'numeric',
            sub_type => undef,
        },
    "Price sub 5 gt 10"                                        =>
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "sub",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  5,
                val_type =>  'numeric',
            },
            value => 10,
            val_type => 'numeric',
            sub_type => undef,
        },
    "Price add 5 gt 10"                                        => 
        {
            operator =>   "gt",
            subject  =>  {
                operator =>  "add",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  5,
                val_type =>  'numeric',
            },
            value => 10,
            val_type => 'numeric',
            sub_type => undef,
        },
    "Price le 3.5 or Price gt 200"                             =>
        {
            operator =>   "or",
            subject  =>  {
                operator =>  "le",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  3.5,
                val_type =>  'numeric',
            },
            value =>     {
                operator =>  "gt",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  200,
                val_type =>  'numeric',
            },
            val_type => undef,
            sub_type => undef,
        },
    "Price le 200 and Price gt 3.5"                            =>
        {
            operator =>   "and",
            subject  =>  {
                operator =>  "le",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  200,
                val_type =>  'numeric',
            },
            value =>     {
                operator =>  "gt",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  3.5,
                val_type =>  'numeric',
            },
            val_type => undef,
            sub_type => undef,
        },
    "Price le 100"                                             =>
        {
            operator =>  "le",
            subject  =>  "Price",
            sub_type =>  "field",
            value    =>  100,
            val_type =>  'numeric',
        },
    "Price lt 20"                                              =>
        {
            operator =>  "lt",
            subject  =>  "Price",
            sub_type =>  "field",
            value    =>  20,
            val_type =>  'numeric',
        },
    "Price ge 10"                                              =>
        {
            operator =>  "ge",
            subject  =>  "Price",
            sub_type =>  "field",
            value    =>  10,
            val_type =>  'numeric',
        },
    "Price gt 20"                                              =>
        {
            operator =>  "gt",
            subject  =>  "Price",
            sub_type =>  "field",
            value    =>  20,
            val_type =>  'numeric',
        },
    "()"                              => undef,
    "Address/City ne 'London'"                                 =>
        {
            operator =>  "ne",
            subject  =>  "Address/City",
            sub_type =>  "field",
            value    =>  "'London'",
            val_type =>  'string',
        },
    "Address/City eq 'Redmond'"                                =>
        {
            operator =>  "eq",
            subject  =>  "Address/City",
            sub_type =>  "field",
            value    =>  "'Redmond'",
            val_type =>  'string',
        },
    "substringof('Alfreds', CompanyName) eq true"  =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "substringof",
                subject  =>  "Alfreds",
                value    =>  "CompanyName",
                val_type =>  "field",
                sub_type =>  "string",
            },
            value    => "true",
            val_type => 'bool',
            sub_type => undef,
        },
    "endswith(CompanyName, 'Futterkiste') eq true" =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "endsWith",
                subject  =>  "CompanyName",
                sub_type =>  "field",
                value    =>  "Futterkiste",
                val_type => 'string',
            },
            value    => "true",
            val_type => 'bool',
            sub_type => undef,
        },
    "startswith(CompanyName, 'Alfr') eq true"      =>
        {
            operator =>  "eq",
            subject  =>  {
                operator =>  "startsWith",
                subject  =>  "CompanyName",
                sub_type =>  "field",
                value    =>  "Alfr",
                val_type => 'string',
            },
            value    => "true",
            val_type => 'bool',
            sub_type => undef,
        },
    "((name eq 'Serena') and (age lt 5))" =>
        {
            operator =>  "and",
            subject  =>   {
                operator =>  "eq",
                subject  =>  "name",
                sub_type =>  "field",
                value    =>  "'Serena'",
                val_type =>  'string',
            },
            value =>     {
                operator =>  "lt",
                subject  =>  "age",
                sub_type =>  "field",
                value    =>  5,
                val_type =>  'numeric',
            },
            val_type => undef,
            sub_type => undef,
        },
    "(Price sub 5) gt 10" =>
        {
            operator =>  "gt",
            subject  =>   {
                operator =>  "sub",
                subject  =>  "Price",
                sub_type =>  "field",
                value    =>  5,
                val_type =>  'numeric',
            },
            value => 10,
            val_type =>  'numeric',
            sub_type => undef,
        },
    "user_id ge 10" =>
        {
            operator =>  "ge",
            subject  =>  "user_id",
            sub_type =>  "field",
            value    =>  10,
            val_type =>  'numeric',
        },
);


for my $filter ( sort keys %tests ) {
    my $vars = parser->( $filter );
    #p $vars;
    is_deeply $vars, $tests{$filter}, $filter;
}

done_testing();
