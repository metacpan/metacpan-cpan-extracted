#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Net::Domain::Info qw(::Whois ::SEO);

my $domain = $ARGV[0] || 'deepapple.com';

my $appid = 'LBcUiHzV34E1ulk41_5fuLUbg9FjryelKhvlilDeej.SGP2.iNudKB_HNoP9dm14gQo-';

# SIMPLE

my $domain_info = Net::Domain::Info->new ($domain);

my $pr = $domain_info->page_rank;

ok defined $pr, "page rank is: $pr";

my $tic = $domain_info->tic;

ok defined $tic, "tic is: $tic";

my $links = $domain_info->inbound_links ($appid);

ok defined $links, "inbound link count is: $links";

use Socket;
my $ip = inet_ntoa (inet_aton ('search.yahooapis.com'));

$links = $domain_info->inbound_links ($appid, host => $ip);

ok defined $links, "inbound link count is: $links, without dns queries";

