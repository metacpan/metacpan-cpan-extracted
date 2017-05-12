#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Net::Domain::Info qw(::Whois ::SEO);
use Encode;

my $domain_raw = 'нфтвучюкг.com';
my $domain_idn = $domain_raw;
unless (Encode::is_utf8 ($domain_idn)) {
	$domain_idn = Encode::decode_utf8 ($domain_idn);
}
my $domain_asc = 'xn--b1acukzhe1a7d.com';

my $domain_info = Net::Domain::Info->new ($domain_idn);

ok $domain_info;
ok $domain_info->name eq $domain_asc;
ok $domain_info->idn  eq $domain_idn;

$domain_info = Net::Domain::Info->new ($domain_asc);

ok $domain_info;
ok $domain_info->name eq $domain_asc;
ok $domain_info->idn  eq $domain_idn;

my $domain = 'the-singlers.us';

$domain_info = Net::Domain::Info->new ($domain);

ok $domain_info;
ok $domain_info->name eq $domain;
ok $domain_info->idn eq $domain;
