#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

use_ok('Net::IPAddress::Filter::IPFilterDat') or die "Unable to compile Net::IPAddress::Filter::IPFilterDat" ;

test_rule_parsing();

done_testing;

exit;

sub test_rule_parsing {

    my $input = "";
    my $expected = undef;
    my $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Blank input gives undef");

    $input = "Hello World";
    $expected = undef;
    $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Random string gives undef");

    $input = "000.000.000.000 - 000.255.255.255 , 000 , invalid ip";
    $expected = {
        start_ip => "000.000.000.000",
        end_ip   => "000.255.255.255",
        score    => "000",
        label    => "invalid ip",
    };
    $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Rule with whitespace parses");

    $input = "000.000.000.000 - 000.255.255.255 , 000 , invalid ip\n";
    $expected = {
        start_ip => "000.000.000.000",
        end_ip   => "000.255.255.255",
        score    => "000",
        label    => "invalid ip",
    };
    $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Rule with trailing newline parses");

    $input = "000.000.000.000-000.255.255.255,000,invalid ip";
    $expected = {
        start_ip => "000.000.000.000",
        end_ip   => "000.255.255.255",
        score    => "000",
        label    => "invalid ip",
    };
    $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Rule without whitespace parses");

    $input = "0.0.0.0-1.1.1.1,9,single digits";
    $expected = {
        start_ip => "0.0.0.0",
        end_ip   => "1.1.1.1",
        score    => "9",
        label    => "single digits",
    };
    $got = Net::IPAddress::Filter::IPFilterDat::_parse_rule($input);
    is_deeply($got, $expected, "_parse_rule() Rule with single-digit quads parses");

}

