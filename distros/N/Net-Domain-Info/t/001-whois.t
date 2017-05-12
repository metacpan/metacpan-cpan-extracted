#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Net::Domain::Info qw(::Whois ::SEO);

my $domain = $ARGV[0] || 'the-singlers.us';

my $domain_info = Net::Domain::Info->new ($domain);

ok $domain_info;

$domain_info->fetch_whois;

ok $domain_info->created, $domain_info->created;

ok $domain_info->expires, $domain_info->expires;

use Data::Dumper;

ok $domain_info->contacts, Dumper $domain_info->contacts;

# $whois