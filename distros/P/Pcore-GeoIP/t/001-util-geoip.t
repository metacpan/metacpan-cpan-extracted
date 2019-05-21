#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;
use Pcore::GeoIP;

our $TESTS = {
    '203.174.65.12'   => 'JP',
    '212.208.74.140'  => 'FR',
    '200.219.192.106' => 'BR',
    '134.102.101.18'  => 'DE',
    '193.75.148.28'   => 'BE',
    '147.251.48.1'    => 'CZ',
    '194.244.83.2'    => 'IT',

    # '203.15.106.23'   => 'AU',
    '196.31.1.1'      => 'ZA',
    '210.54.22.1'     => 'NZ',
    '210.25.5.5'      => 'CN',
    '210.54.122.1'    => 'NZ',
    '210.25.15.5'     => 'CN',
    '192.37.51.100'   => 'CH',
    '192.37.150.150'  => 'CH',
    '192.106.51.100'  => 'IT',
    '192.106.150.150' => 'IT',
};

plan tests => scalar keys $TESTS->%*;

for my $ip ( keys $TESTS->%* ) {
    ok( P->geoip->country->record_for_address($ip)->{country}->{iso_code} eq $TESTS->{$ip}, 'country_code_by_addr_' . $ip );
}

done_testing scalar keys $TESTS->%*;

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 33                   | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=cut
