use strict;
use Test::More;
use t::Util;
use Sys::PageCache;

use POSIX qw(sysconf _SC_PAGESIZE);
use Fcntl qw(:seek);

my $page_size = sysconf(_SC_PAGESIZE);
diag "page_size: $page_size";
my $pages = 8;

my $file_size = $page_size * $pages + 1024;
my($fh, $filename) = t::Util::create_tempfile(size => $file_size);
diag "tempfile: $filename";

sub cache_and_test {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $buf = do { seek $fh, 0, SEEK_SET; local $/; <$fh> };

    my $r = fincore $filename;

    ok($r, "return value");
    is(ref($r), 'HASH', 'return value of fincore is hashref');

    is($r->{total_pages},  $pages+1, "total pages");
    is($r->{cached_pages}, $pages+1, "cached pages");

    my $retval = Test::More::subtest(@_);

    return $retval;
}

cache_and_test "1.0" => sub {
    my $r = fadvise $filename, 0, int($file_size * 1.0), POSIX_FADV_DONTNEED;

    is($r, 1, "return value of fadvise");

    $r = fincore $filename;

    ok($r, "return value of fincore");
    is(ref($r), 'HASH', 'return value of fincore is hashref');

    is($r->{total_pages},  $pages+1, "total pages");
    ok($r->{cached_pages} == 0, "cached pages $r->{cached_pages} == 0");
};

cache_and_test "0.6" => sub {
    my $r = fadvise $filename, 0, int($file_size * 0.6), POSIX_FADV_DONTNEED;

    is($r, 1, "return value of fadvise");

    $r = fincore $filename;

    ok($r, "return value of fincore");
    is(ref($r), 'HASH', 'return value of fincore is hashref');

    is($r->{total_pages},  $pages+1, "total pages");
    ok($r->{cached_pages} > 0,        "cached pages $r->{cached_pages} > 0");
    ok($r->{cached_pages} < $pages+1, "cached pages $r->{cached_pages} < $pages+1");
};

done_testing;
