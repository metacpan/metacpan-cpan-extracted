use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Pod::Coverage;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustMe' });
