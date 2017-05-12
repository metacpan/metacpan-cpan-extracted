use Test::Most;

BEGIN {
plan skip_all => 'AUTHOR_MODE not set' unless $ENV{AUTHOR_MODE};
plan skip_all => "Test::Pod 1.22 required for testing POD, err $@" 
  unless eval "use Test::Pod 1.22; 1";
}

all_pod_files_ok;
done_testing;
