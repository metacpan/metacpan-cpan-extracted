use strict;
use Test::More;
use t::Util;
use Sys::PageCache;

use POSIX qw(sysconf _SC_PAGESIZE);
use Fcntl qw(:seek);

my $page_size = sysconf(_SC_PAGESIZE);
diag "page_size: $page_size";
my $pages = 8;

my($fh, $filename) = t::Util::create_tempfile(size => $page_size * $pages + 1024);
diag "tempfile: $filename";

my $r = fincore $filename;

ok($r, "return value");
is(ref($r), 'HASH', 'return value is hashref');

is($r->{total_pages},  $pages+1, "total pages");
is($r->{cached_pages}, $pages+1, "cached pages");

done_testing;
