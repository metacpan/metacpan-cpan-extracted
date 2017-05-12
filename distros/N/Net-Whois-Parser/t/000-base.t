#!/usr/bin/perl

use strict;

use Test::More;

use lib qw( lib ../lib );

use Net::Whois::Raw;
use Net::Whois::Parser;
$Net::Whois::Parser::DEBUG = 2;

my $domain = 'reg.ru';
my $info;

plan tests => 12;

my ( $raw, $server ) = whois($domain);


ok parse_whois(raw => $raw, server => $server), "parse_whois $domain, $server";
ok parse_whois(raw => $raw, domain => $domain), "parse_whois $domain, $server";
ok parse_whois(domain => $domain), "parse_whois $domain, $server";

ok !parse_whois(domain => 'iweufhweufhweufh.ru'), 'domain not exists';

$info = parse_whois(raw => $raw, server => $server);
is $info->{nameservers}->[0]->{domain}, 'ns1.reg.ru', 'reg.ru ns 1';
is $info->{nameservers}->[1]->{domain}, 'ns2.reg.ru', 'reg.ru ns 2';
is $info->{domain}, 'REG.RU', 'reg.ru domain';

$raw = "
    Test   1: test
 Test-2:wefwef wef
  test3: value:value
  test4.....: value
";
$info = parse_whois( raw => $raw, server => 'whois.ripn.net' );

ok exists $info->{'test_1'}, 'field name with spaces';
ok exists $info->{'test_2'}, 'field with -';
is $info->{'test3'}, 'value:value', 'field value with :';
is $info->{'test4'}, 'value', 'field value with :';

####
$Net::Whois::Parser::GET_ALL_VALUES = 1;

$raw = [
    { text => "test: 1" },
    { text => "tEst: 2" },
    { text => "test: 3" },
];
$info = parse_whois( raw => $raw, server => 'whois.ripn.net' );

is_deeply $info->{test}, [ 1, 2, 3], 'get_all_values is on';


