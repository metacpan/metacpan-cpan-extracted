use Test::More;

plan skip_all => 'author test' unless ($ENV{RELEASE_TESTING});

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();

