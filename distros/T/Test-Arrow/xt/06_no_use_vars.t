use Test::Arrow;
eval "use Test::Vars";
Test::Arrow->plan(skip_all => 'Test::Vars required for testing for unused vars') if $@;
all_vars_ok();
