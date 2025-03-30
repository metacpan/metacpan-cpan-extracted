use strict;
use warnings;
use Test::Needs qw(Pod::Coverage);

use Test::More;
use Test::Pod::Coverage::TrustMe;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage' });
