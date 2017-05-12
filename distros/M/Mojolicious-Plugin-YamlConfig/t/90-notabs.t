use Test::More;
plan skip_all => "author test" unless $ENV{RELEASE_TESTING};

eval 'use Test::NoTabs; 1'
? all_perl_files_ok()
: plan skip_all => "Test::NoTabs required";
