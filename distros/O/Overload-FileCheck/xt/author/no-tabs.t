use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Overload/FileCheck.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_boot.t',
    't/02_basic-mock.t',
    't/02_import.t',
    't/exporter-all.t',
    't/exporter.t',
    't/issue-0001.t',
    't/mock-all-file-checks.t',
    't/mock-all-from-stat_advanced.t',
    't/mock-all-from-stat_basic.t',
    't/mock-lstat.t',
    't/mock-setting-errno.t',
    't/mock-stat.t',
    't/recycle-stat.t',
    't/simple-test.t',
    't/stat-helpers.t',
    't/test-A.t',
    't/test-B-uppercase.t',
    't/test-C-uppercase.t',
    't/test-M.t',
    't/test-O-uppercase.t',
    't/test-R-uppercase.t',
    't/test-S-uppercase.t',
    't/test-T-uppercase.t',
    't/test-W-uppercase.t',
    't/test-X-uppercase.t',
    't/test-b.t',
    't/test-c.t',
    't/test-d.t',
    't/test-e.t',
    't/test-f.t',
    't/test-g.t',
    't/test-integer.t',
    't/test-k.t',
    't/test-l.t',
    't/test-o.t',
    't/test-p.t',
    't/test-r.t',
    't/test-s.t',
    't/test-t.t',
    't/test-true-false.t',
    't/test-u.t',
    't/test-w.t',
    't/test-x.t',
    't/test-z.t',
    't/xt-author-check-examples.t'
);

notabs_ok($_) foreach @files;
done_testing;
