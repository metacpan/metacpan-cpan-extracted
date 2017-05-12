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

my $advice = POSIX_FADV_DONTNEED;
ok(defined $advice, "POSIX_FADV_DONTNEED defined");
ok($advice > 0, "POSIX_FADV_DONTNEED > 0");

$r = fadvise $filename, 0, 0, POSIX_FADV_DONTNEED;

is($r, 1, "return value of fadvise");

$r = fincore $filename;

ok($r, "return value");
is(ref($r), 'HASH', 'return value is hashref');

is($r->{total_pages},  $pages+1, "total pages");
is($r->{cached_pages}, 0,        "cached pages (0)");

done_testing;
