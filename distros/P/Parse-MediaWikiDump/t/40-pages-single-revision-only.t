#!perl -w

use strict;
use warnings;

use Test::Exception tests => 1;
use Parse::MediaWikiDump;

my $file = 't/revisions_test.xml';

throws_ok { test() } qr/^only one revision per page is allowed$/, 'one revision per article ok';

sub test {	
	my $pages = Parse::MediaWikiDump->pages($file);
	
	while(defined($pages->next)) { };
};



