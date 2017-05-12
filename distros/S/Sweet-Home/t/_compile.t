use strict;
use warnings;
use Test::More;
eval "use Test::Compile";
plan skip_all => "Test::Compile required for testing compilation"
  if $@;
all_pm_files_ok();
