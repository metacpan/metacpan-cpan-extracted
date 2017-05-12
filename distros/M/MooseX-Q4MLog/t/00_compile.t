use strict;
use Test::More;
eval { require Test::Compile; Test::Compile->import };
if ($@) {
    plan(skip_all => "Test::Compile required for testing compilation: $@");
} else {
    Test::Compile::all_pm_files_ok();
}