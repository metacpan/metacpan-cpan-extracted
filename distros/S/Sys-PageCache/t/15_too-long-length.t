use strict;
use Test::More;
use Test::Output;
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

my $r;

subtest "fadvise" => sub {
    stderr_like {
        $r = fadvise $filename,    0, $file_size*2, POSIX_FADV_DONTNEED;
    } qr/is greater than file size/, "fadvise 0, fsize*2";
    ok(defined $r);

    stderr_like {
        $r = fadvise $filename, 8192, $file_size*2, POSIX_FADV_DONTNEED;
    } qr/is greater than file size/, "fadvise 8192, fsize*2";
    ok(defined $r);

    stderr_like {
        $r = fadvise $filename, 8192, $file_size,   POSIX_FADV_DONTNEED;
    } qr/is greater than file size/, "fadvise 8192, fsize";
    ok(defined $r);
};

subtest "fincore" => sub {
    stderr_like {
        $r = fincore $filename,    0, $file_size*2;
    } qr/is greater than file size/, "fincore 0, fsize*2n";
    ok($r);

    stderr_like {
        $r = fincore $filename, 8192, $file_size*2;
    } qr/is greater than file size/, "fincore 8192, fsize*2";
    ok($r);
};

done_testing;
