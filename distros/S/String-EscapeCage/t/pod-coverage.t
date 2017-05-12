#!perl -T

use warnings;
use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({ also_private =>
  [qr/^(stringify|concat|numify|boolify|uncageany|untaint)$/] });
