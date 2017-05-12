#!perl 

use Test::Simple tests =>4;
use strict;
use warnings;
use Parse::MediaWikiDump;

my $file = 't/links_test.sql';

my $links = Parse::MediaWikiDump->links($file);

my $sum;
my $last_link;

while(my $link = $links->next) {
	$sum += $link->from;
	$last_link = $link;
}

ok($sum == 92288);
ok($last_link->from == 7759);
ok($last_link->to eq 'Recentchanges');
ok($last_link->namespace == -1);
