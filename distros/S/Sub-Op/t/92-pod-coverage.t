#!perl -T

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04 (tests => 1)";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
pod_coverage_ok(
 'Sub::Op',
 {
  also_private => [
   qr/^_/,
   qr/^CLONE(_SKIP)?$/,
   'dl_load_flags',
  ],
 },
 'Sub::Op is covered',
);
