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

my $r;

$r = fadvise $filename, 0, 0, POSIX_FADV_DONTNEED;
$r = fincore $filename;
my $file_size = $r->{file_size};

is($r->{total_pages},  $pages+1, "total pages");
is($r->{cached_pages}, 0,        "cached pages (0)");

seek $fh, 0, SEEK_SET;
my $buf;
$r = sysread $fh, $buf, 512, 0;

$r = fincore $filename;

is($r->{total_pages},  $pages+1, "total pages");
ok($r->{cached_pages} < $pages+1, "cached pages $r->{cached_pages} < $pages + 1");

my $offset = $r->{cached_pages} * $page_size + $page_size;
diag "offset: $offset";
$r = fincore $filename, $offset, $file_size-$offset;

is($r->{total_pages},  $pages+1, "total pages");
ok($r->{cached_pages} == 0, "cached pages $r->{cached_pages} == 0");

$r = fincore $filename;

is($r->{total_pages},  $pages+1, "total pages");
ok($r->{cached_pages} < $pages+1, "cached pages $r->{cached_pages} < $pages + 1");

done_testing;
