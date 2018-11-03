
use Test::More;
use Test::Pod;

my @dirs = qw(lib);
all_pod_files_ok(all_pod_files(@dirs));
