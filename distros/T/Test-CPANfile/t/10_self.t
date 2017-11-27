use strict;
use warnings;
use Test::CPANfile;
use Test::More;

cpanfile_has_all_used_modules(
  recommends => 1,
  suggests => 1,
);

done_testing;
