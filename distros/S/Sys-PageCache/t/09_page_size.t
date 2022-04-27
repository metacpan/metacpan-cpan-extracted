use strict;
use Test::More;

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..');

use t::Util;
use Sys::PageCache;

my $page_size = page_size();
diag "page_size: $page_size";

ok($page_size, "page_size");
ok($page_size > 0, "page_size > 0");

done_testing;
