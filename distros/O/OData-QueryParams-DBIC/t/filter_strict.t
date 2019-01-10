#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use OData::QueryParams::DBIC;

my %tests = (
    q!$filter=substringof('Alfreds', CompanyName) eq true!  => 'FAIL',
    q!$filter=endswith(CompanyName, 'Futterkiste') eq true! => 'FAIL',
    q!$filter=startswith(CompanyName, 'Alfr') eq true!      => 'FAIL',
    q!$filter=length(CompanyName) eq 19!                    => 'FAIL',
    q!$filter=indexof(CompanyName, 'lfreds') eq 1!          => 'FAIL',
    q!$filter=replace(CompanyName, ' ', '') eq 'AlfredsFutterkiste'! => 'FAIL',
    q!$filter=substring(CompanyName, 1) eq 'lfreds Futterkiste'!     => 'FAIL',
    q!$filter=substring(CompanyName, 1, 2) eq 'lf'!                  => 'FAIL',
    q!$filter=tolower(CompanyName) eq 'alfreds futterkiste'!         => 'FAIL',
    q!$filter=toupper(CompanyName) eq 'ALFREDS FUTTERKISTE'!         => 'FAIL',
    q!$filter=trim(CompanyName) eq 'Alfreds Futterkiste'!            => 'FAIL',
    q!$filter=concat(concat(City, ', '), Country) eq 'Berlin, Germany'! => 'FAIL',
    q!$filter=day(BirthDate) eq 8!                                      => 'FAIL',
    q!$filter=hour(BirthDate) eq 0!                                     => 'FAIL',
    q!$filter=minute(BirthDate) eq 0!                                   => 'FAIL',
    q!$filter=month(BirthDate) eq 12!                                   => 'FAIL',
    q!$filter=filter=second(BirthDate) eq 0!                            => 'FAIL',
    q!$filter=year(BirthDate) eq 1948!                                  => 'FAIL',
    q!$filter=round(Freight) eq 32d!                                    => 'FAIL',
    q!$filter=round(Freight) eq 32!                                     => 'FAIL',
    q!$filter=floor(Freight) eq 32d!                                    => 'FAIL',
    q!$filter=floor(Freight) eq 32!                                     => 'FAIL',
    q!$filter=ceiling(Freight) eq 33d!                                  => 'FAIL',
    q!$filter=ceiling(Freight) eq 33!                                   => 'FAIL',
    q!$filter=isof('NorthwindModel.Order')!                             => 'FAIL',
    q!$filter=isof(ShipCountry, 'Edm.String')!                          => 'FAIL',
    q!$filter=(Price sub 5) gt 10!                                      => 'FAIL',
    q!$filter=Price mod 2 eq 0!                                         => 'FAIL',
    q!$filter=Price div 2 gt 4!                                         => 'FAIL',
    q!$filter=Price mul 2 gt 2000!                                      => 'FAIL',
    q!$filter=Price sub 5 gt 10!                                        => 'FAIL',
    q!$filter=Price add 5 gt 10!                                        => 'FAIL',
    q!$filter=not endswith(Description,'milk')!                         => 'FAIL',
    q!$filter=Price le 3.5 or Price gt 200!                             => { -or  => [ { Price => { '<=' => 3.5 } }, { Price => { '>' => 200 } } ] },
    q!$filter=Price le 200 and Price gt 3.5!                            => { -and => [ { Price => { '<=' => 200 } }, { Price => { '>' => 3.5 } } ] },
    q!$filter=Price le 100!                                             => { Price => { '<=' => 100 } },
    q!$filter=Price lt 20!                                              => { Price => { '<' => 20 } },
    q!$filter=Price ge 10!                                              => { Price => { '>=' => 10 } },
    q!$filter=Price gt 20!                                              => { Price => { '>' => 20 } },
    q!$filter=Address/City ne 'London'!                                 => { 'Address.City' => { '!=' => 'London' } },
    q!$filter=Address/City eq 'Redmond'!                                => { 'Address.City' => { '=' => 'Redmond' } },
    q!$filter=((name eq 'Serena') and (age lt 5))!                      => { -and => [ { name => { '=' => 'Serena' } }, { age => { '<' => 5 } } ] },
    q!$filter=user_id gt 20!                                            => { user_id => { '>' => 20 } },
    q!$filter=!                                                         => {},
);

QUERYSTRING:
for my $query_string ( sort keys %tests ) {
    my $expected = $tests{$query_string};

    if ( !ref $expected && $expected eq 'FAIL' ) {
        dies_ok {
            params_to_dbic( $query_string, strict => 1 );
        };
        next QUERYSTRING;
    }

    my ($where,$opts) = params_to_dbic( $query_string, strict => 1 );
    is_deeply $where, $tests{$query_string}, 'Query: ' . $query_string;
}

done_testing();
