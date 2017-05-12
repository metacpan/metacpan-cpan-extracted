use strict;
use Test::More;
eval "use Test::Portability::Files";
plan skip_all => "Test::Portability::Files required for testing filenames portability" if $@;

# uncomment the following line to test every file in the current distribution
#options(use_file_find => 1);

# run the selected tests
run_tests();
