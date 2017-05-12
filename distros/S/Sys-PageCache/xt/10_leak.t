use strict;
use Test::More;
use Test::LeakTrace;
use t::Util;
use Sys::PageCache;

my($fh, $filename) = t::Util::create_tempfile(size => 8192);

no_leaks_ok {
    my $r = fincore $filename;
} 'fincore';

no_leaks_ok {
    my $r = fadvise $filename, 0, 0, POSIX_FADV_DONTNEED;
} 'fadvise';

done_testing;
