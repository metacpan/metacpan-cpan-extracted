# $Id: 02-search.t 267 2006-06-09 05:43:51Z knok $
#

use strict;
use Test;
use Search::Namazu;

BEGIN { plan tests => 2 };

# test in English
my @r;
@r = Search::Namazu::Search(index => ['t/index/en'], query => 'namazu',
	 lang => 'C');
ok($#r == 1);
@r = Search::Namazu::Search(index => ['t/index/en'], query => 'plain',
	 lang => 'C');
ok($#r == 0);
