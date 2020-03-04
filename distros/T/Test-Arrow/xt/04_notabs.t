use Test::Arrow;
eval "use Test::NoTabs";
Test::Arrow->plan(skip_all => "Test::NoTabs required for testing POD") if $@;
all_perl_files_ok('lib');
