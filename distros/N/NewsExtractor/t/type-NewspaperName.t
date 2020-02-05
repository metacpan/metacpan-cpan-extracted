use utf8;
use strict;

use NewsExtractor::Types qw(is_NewspaperName);

use Test2::V0;

ok ! is_NewspaperName("XXX Paper");
ok is_NewspaperName("中央社");

done_testing;
