#! perl -I. -w
use t::Test::abeltje;

use Test::Pod::Coverage;

Test::Warnings->import(':no_end_test');
all_pod_coverage_ok();
