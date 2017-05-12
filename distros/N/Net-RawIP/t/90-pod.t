use strict;
use warnings;
use Test::More;


plan skip_all => "Author tests" unless $ENV{AUTHOR_MODE};
plan skip_all => "Test::Pod 1.00 required for testing POD"
    unless eval "use Test::Pod; 1";

all_pod_files_ok(all_pod_files('.'));
