#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use OData::QueryParams::DBIC;

my %tests = (
    "filter=substringof('Alfreds', CompanyName) eq true"  => 'FAIL',
    "filter=endswith(CompanyName, 'Futterkiste') eq true" => 'FAIL',
    "filter=startswith(CompanyName, 'Alfr') eq true"      => 'FAIL',
    "filter=length(CompanyName) eq 19"                    => 'FAIL',
    "filter=indexof(CompanyName, 'lfreds') eq 1"          => 'FAIL',
    "filter=replace(CompanyName, ' ', '') eq 'AlfredsFutterkiste'" => 'FAIL',
    "filter=substring(CompanyName, 1) eq 'lfreds Futterkiste'"     => 'FAIL',
    "filter=substring(CompanyName, 1, 2) eq 'lf'"                  => 'FAIL',
    "filter=tolower(CompanyName) eq 'alfreds futterkiste'"         => 'FAIL',
    "filter=toupper(CompanyName) eq 'ALFREDS FUTTERKISTE'"         => 'FAIL',
    "filter=trim(CompanyName) eq 'Alfreds Futterkiste'"            => 'FAIL',
    "filter=concat(concat(City, ', '), Country) eq 'Berlin, Germany'" => 'FAIL',
    "filter=day(BirthDate) eq 8"                                      => 'FAIL',
    "filter=hour(BirthDate) eq 0"                                     => 'FAIL',
    "filter=minute(BirthDate) eq 0"                                   => 'FAIL',
    "filter=month(BirthDate) eq 12"                                   => 'FAIL',
    "filter=filter=second(BirthDate) eq 0"                            => 'FAIL',
    "filter=year(BirthDate) eq 1948"                                  => 'FAIL',
    "filter=round(Freight) eq 32d"                                    => 'FAIL',
    "filter=round(Freight) eq 32"                                     => 'FAIL',
    "filter=floor(Freight) eq 32d"                                    => 'FAIL',
    "filter=floor(Freight) eq 32"                                     => 'FAIL',
    "filter=ceiling(Freight) eq 33d"                                  => 'FAIL',
    "filter=ceiling(Freight) eq 33"                                   => 'FAIL',
    "filter=isof('NorthwindModel.Order')"                             => 'FAIL',
    "filter=isof(ShipCountry, 'Edm.String')"                          => 'FAIL',
    "filter=(Price sub 5) gt 10"                                      => 'FAIL',
    "filter=Price mod 2 eq 0"                                         => 'FAIL',
    "filter=Price div 2 gt 4"                                         => 'FAIL',
    "filter=Price mul 2 gt 2000"                                      => 'FAIL',
    "filter=Price sub 5 gt 10"                                        => 'FAIL',
    "filter=Price add 5 gt 10"                                        => 'FAIL',
    "filter=not endswith(Description,'milk')"                         => 'FAIL',
    "filter=Price le 3.5 or Price gt 200"                             => { -or  => [ { Price => { '<=' => 3.5 } }, { Price => { '>' => 200 } } ] },
    "filter=Price le 200 and Price gt 3.5"                            => { -and => [ { Price => { '<=' => 200 } }, { Price => { '>' => 3.5 } } ] },
    "filter=Price le 100"                                             => { Price => { '<=' => 100 } },
    "filter=Price lt 20"                                              => { Price => { '<' => 20 } },
    "filter=Price ge 10"                                              => { Price => { '>=' => 10 } },
    "filter=Price gt 20"                                              => { Price => { '>' => 20 } },
    "filter=Address/City ne 'London'"                                 => { 'Address.City' => { '!=' => 'London' } },
    "filter=Address/City eq 'Redmond'"                                => { 'Address.City' => { '==' => 'Redmond' } },
    "filter=((name eq 'Serena') and (age lt 5))"                      => { -and => [ { name => { '==' => 'Serena' } }, { age => { '<' => 5 } } ] },
);

QUERYSTRING:
for my $query_string ( sort keys %tests ) {
    my $expected = $tests{$query_string};

    if ( !ref $expected && $expected eq 'FAIL' ) {
        dies_ok {
            params_to_dbic( $query_string );
        };
        next QUERYSTRING;
    }

    my ($where,$opts) = params_to_dbic( $query_string );
    is_deeply $where, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
