use strict;
use Test::More;
use t::Util;
use Sys::PageCache;

my $page_size = page_size();
diag "page_size: $page_size";

ok($page_size, "page_size");
ok($page_size > 0, "page_size > 0");

done_testing;
