use Test::More;
plan skip_all => "POD tests only run for the developer"
  unless $ENV{USER} eq 'slanning';

eval "use Test::Pod 1.26";
plan skip_all => "Test::Pod 1.26 required for testing POD"
  if $@;

all_pod_files_ok();
